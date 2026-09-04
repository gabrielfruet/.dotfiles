#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "torch==2.14.0",
#     "numpy==2.5.2",
#     "imageio-ffmpeg==0.6.0",
#     "huggingface-hub==1.30.0",
# ]
# [tool.uv]
# exclude-newer = "2026-09-04T00:00:00Z"
# ///
"""Fast GPU face blurring: mp4 in, mp4 out.

Detector is RetinaFace with a MobileNetV1-0.25 backbone (~1.0 GFLOP at
640x640, 1.7 MB of weights), run in fp16 with Conv+BN folded, channels_last
and CUDA graphs. Everything downstream of the detector -- mask rasterisation,
blur, compositing -- is a fixed-shape batched tensor op, so there is no Python
loop over faces and no host synchronisation inside the frame loop.

Frames move as yuv420p (1.5 bytes/px) rather than rgb24 (3 bytes/px), which
halves pipe and PCIe traffic. The blur is applied directly to the Y/U/V planes;
RGB only ever exists at detector resolution.

  uv run face_blur.py in.mp4 out.mp4
  uv run face_blur.py --benchmark --allow-random
"""

from __future__ import annotations

import argparse
import json
import math
import os
import queue
import re
import shutil
import statistics
import subprocess
import sys
import threading
import time
import urllib.request
from dataclasses import dataclass
from itertools import product
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F

# Mirror of `mobilenet0.25_Final.pth` from biubug6/Pytorch_Retinaface.
# Override with --weights (a path, an http(s) URL, or hf:REPO_ID:FILENAME)
# or the FACE_BLUR_WEIGHTS environment variable.
DEFAULT_WEIGHTS = "hf:ManishThota/retinaface_mobilenet:mobilenet0.25_Final.pth"
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "face_blur"

# RetinaFace mobilenet0.25 configuration (biubug6/Pytorch_Retinaface cfg_mnet).
MIN_SIZES = [[16, 32], [64, 128], [256, 512]]
STEPS = [8, 16, 32]
VARIANCE = [0.1, 0.2]
IN_CHANNEL = 32
OUT_CHANNEL = 64
# BGR means the reference implementation subtracts; no /255 scaling.
BGR_MEAN = (104.0, 117.0, 123.0)

MASK_DOWNSCALE = 8  # mask is rasterised at frame/8 and bilinearly upsampled
FEATHER_GAIN = 4.0  # edge softness of the superellipse falloff


# --------------------------------------------------------------------------
# Model: RetinaFace / MobileNetV1-0.25
#
# Layer names and shapes match the released `mobilenet0.25_Final.pth` so the
# checkpoint loads with strict=True.
# --------------------------------------------------------------------------


def conv_bn(inp, oup, stride=1, leaky=0.0):
    return nn.Sequential(
        nn.Conv2d(inp, oup, 3, stride, 1, bias=False),
        nn.BatchNorm2d(oup),
        nn.LeakyReLU(negative_slope=leaky, inplace=True),
    )


def conv_bn_no_relu(inp, oup, stride):
    return nn.Sequential(
        nn.Conv2d(inp, oup, 3, stride, 1, bias=False),
        nn.BatchNorm2d(oup),
    )


def conv_bn1x1(inp, oup, stride, leaky=0.0):
    return nn.Sequential(
        nn.Conv2d(inp, oup, 1, stride, 0, bias=False),
        nn.BatchNorm2d(oup),
        nn.LeakyReLU(negative_slope=leaky, inplace=True),
    )


def conv_dw(inp, oup, stride, leaky=0.1):
    return nn.Sequential(
        nn.Conv2d(inp, inp, 3, stride, 1, groups=inp, bias=False),
        nn.BatchNorm2d(inp),
        nn.LeakyReLU(negative_slope=leaky, inplace=True),
        nn.Conv2d(inp, oup, 1, 1, 0, bias=False),
        nn.BatchNorm2d(oup),
        nn.LeakyReLU(negative_slope=leaky, inplace=True),
    )


class MobileNetV1(nn.Module):
    def __init__(self):
        super().__init__()
        self.stage1 = nn.Sequential(
            conv_bn(3, 8, 2, leaky=0.1),
            conv_dw(8, 16, 1),
            conv_dw(16, 32, 2),
            conv_dw(32, 32, 1),
            conv_dw(32, 64, 2),
            conv_dw(64, 64, 1),
        )
        self.stage2 = nn.Sequential(
            conv_dw(64, 128, 2),
            conv_dw(128, 128, 1),
            conv_dw(128, 128, 1),
            conv_dw(128, 128, 1),
            conv_dw(128, 128, 1),
            conv_dw(128, 128, 1),
        )
        self.stage3 = nn.Sequential(
            conv_dw(128, 256, 2),
            conv_dw(256, 256, 1),
        )

    def forward(self, x):
        x1 = self.stage1(x)
        x2 = self.stage2(x1)
        x3 = self.stage3(x2)
        return x1, x2, x3


class FPN(nn.Module):
    def __init__(self, in_channels_list, out_channels):
        super().__init__()
        leaky = 0.1 if out_channels <= 64 else 0.0
        self.output1 = conv_bn1x1(in_channels_list[0], out_channels, 1, leaky=leaky)
        self.output2 = conv_bn1x1(in_channels_list[1], out_channels, 1, leaky=leaky)
        self.output3 = conv_bn1x1(in_channels_list[2], out_channels, 1, leaky=leaky)
        self.merge1 = conv_bn(out_channels, out_channels, leaky=leaky)
        self.merge2 = conv_bn(out_channels, out_channels, leaky=leaky)

    def forward(self, feats):
        o1 = self.output1(feats[0])
        o2 = self.output2(feats[1])
        o3 = self.output3(feats[2])
        o2 = self.merge2(o2 + F.interpolate(o3, size=o2.shape[2:], mode="nearest"))
        o1 = self.merge1(o1 + F.interpolate(o2, size=o1.shape[2:], mode="nearest"))
        return o1, o2, o3


class SSH(nn.Module):
    def __init__(self, in_channel, out_channel):
        super().__init__()
        assert out_channel % 4 == 0
        leaky = 0.1 if out_channel <= 64 else 0.0
        self.conv3X3 = conv_bn_no_relu(in_channel, out_channel // 2, stride=1)
        self.conv5X5_1 = conv_bn(in_channel, out_channel // 4, stride=1, leaky=leaky)
        self.conv5X5_2 = conv_bn_no_relu(out_channel // 4, out_channel // 4, stride=1)
        self.conv7X7_2 = conv_bn(out_channel // 4, out_channel // 4, stride=1, leaky=leaky)
        self.conv7x7_3 = conv_bn_no_relu(out_channel // 4, out_channel // 4, stride=1)

    def forward(self, x):
        c3 = self.conv3X3(x)
        c5_1 = self.conv5X5_1(x)
        c5 = self.conv5X5_2(c5_1)
        c7 = self.conv7x7_3(self.conv7X7_2(c5_1))
        return F.relu(torch.cat([c3, c5, c7], dim=1))


class _Head(nn.Module):
    def __init__(self, inchannels, num_anchors, per_anchor):
        super().__init__()
        self.per_anchor = per_anchor
        self.conv1x1 = nn.Conv2d(inchannels, num_anchors * per_anchor, 1, 1, 0)

    def forward(self, x):
        out = self.conv1x1(x).permute(0, 2, 3, 1).contiguous()
        return out.view(out.shape[0], -1, self.per_anchor)


class RetinaFace(nn.Module):
    """Inference-only RetinaFace. Landmark head is kept so the released
    checkpoint loads strictly, but it is not evaluated."""

    def __init__(self, num_anchors=2):
        super().__init__()
        self.body = MobileNetV1()
        in_list = [IN_CHANNEL * 2, IN_CHANNEL * 4, IN_CHANNEL * 8]
        self.fpn = FPN(in_list, OUT_CHANNEL)
        self.ssh1 = SSH(OUT_CHANNEL, OUT_CHANNEL)
        self.ssh2 = SSH(OUT_CHANNEL, OUT_CHANNEL)
        self.ssh3 = SSH(OUT_CHANNEL, OUT_CHANNEL)
        self.ClassHead = nn.ModuleList(_Head(OUT_CHANNEL, num_anchors, 2) for _ in range(3))
        self.BboxHead = nn.ModuleList(_Head(OUT_CHANNEL, num_anchors, 4) for _ in range(3))
        self.LandmarkHead = nn.ModuleList(_Head(OUT_CHANNEL, num_anchors, 10) for _ in range(3))

    def forward(self, x):
        f = self.fpn(self.body(x))
        feats = (self.ssh1(f[0]), self.ssh2(f[1]), self.ssh3(f[2]))
        bbox = torch.cat([h(t) for h, t in zip(self.BboxHead, feats)], dim=1)
        cls = torch.cat([h(t) for h, t in zip(self.ClassHead, feats)], dim=1)
        # Face probability only; softmax over 2 classes reduces to a sigmoid
        # of the logit difference, which is one op cheaper.
        score = torch.sigmoid(cls[..., 1] - cls[..., 0])
        return bbox, score


def prior_boxes(height: int, width: int) -> torch.Tensor:
    """Anchors as (cx, cy, w, h) normalised to [0, 1], in head output order."""
    anchors = []
    for k, step in enumerate(STEPS):
        fh, fw = math.ceil(height / step), math.ceil(width / step)
        for i, j in product(range(fh), range(fw)):
            for min_size in MIN_SIZES[k]:
                anchors.append(
                    [
                        (j + 0.5) * step / width,
                        (i + 0.5) * step / height,
                        min_size / width,
                        min_size / height,
                    ]
                )
    return torch.tensor(anchors, dtype=torch.float32)


def decode_boxes(loc: torch.Tensor, priors: torch.Tensor) -> torch.Tensor:
    """(B, N, 4) offsets -> (B, N, 4) x1y1x2y2 boxes normalised to [0, 1]."""
    cxy = priors[..., :2] + loc[..., :2] * VARIANCE[0] * priors[..., 2:]
    wh = priors[..., 2:] * torch.exp(loc[..., 2:] * VARIANCE[1])
    half = wh * 0.5
    return torch.cat([cxy - half, cxy + half], dim=-1)


def fuse_conv_bn(module: nn.Module) -> nn.Module:
    """Fold every Conv2d+BatchNorm2d pair inside nn.Sequential containers.

    A depthwise-separable backbone is dominated by launch overhead, so removing
    ~50 BatchNorm kernels is worth more here than it would be on a big model.
    """
    for name, child in module.named_children():
        fuse_conv_bn(child)  # depth first: the backbone nests Sequentials
        if not isinstance(child, nn.Sequential):
            continue
        fused, prev_idx = [], None
        for layer in child:
            if isinstance(layer, nn.BatchNorm2d) and prev_idx is not None:
                fused[prev_idx] = torch.nn.utils.fusion.fuse_conv_bn_eval(
                    fused[prev_idx], layer
                )
                prev_idx = None
            else:
                prev_idx = len(fused) if isinstance(layer, nn.Conv2d) else None
                fused.append(layer)
        setattr(module, name, nn.Sequential(*fused))
    return module


# --------------------------------------------------------------------------
# Weights
# --------------------------------------------------------------------------


def resolve_weights(spec: str) -> Path:
    """Accepts a local path, an http(s) URL, or hf:REPO_ID:FILENAME."""
    if spec.startswith("hf:"):
        _, repo_id, filename = spec.split(":", 2)
        from huggingface_hub import hf_hub_download

        return Path(hf_hub_download(repo_id=repo_id, filename=filename))
    if spec.startswith(("http://", "https://")):
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        dest = CACHE_DIR / spec.rsplit("/", 1)[-1]
        if not dest.exists():
            tmp = dest.with_suffix(dest.suffix + ".part")
            urllib.request.urlretrieve(spec, tmp)  # noqa: S310 - scheme checked above
            tmp.rename(dest)
        return dest
    path = Path(spec).expanduser()
    if not path.exists():
        raise FileNotFoundError(f"weights not found: {path}")
    return path


WEIGHTS_HELP = """\
Could not fetch RetinaFace weights ({spec}): {err}

The file needed is `mobilenet0.25_Final.pth` (1.7 MB) from
biubug6/Pytorch_Retinaface. Point the script at your own copy with either:

    --weights /path/to/mobilenet0.25_Final.pth
    --weights https://your-mirror/mobilenet0.25_Final.pth
    --weights hf:SOME_REPO:mobilenet0.25_Final.pth
    export FACE_BLUR_WEIGHTS=...

Use --allow-random to run with untrained weights (benchmarking only -- it will
not blur anything).\
"""


def build_model(spec: str, allow_random: bool) -> RetinaFace:
    model = RetinaFace().eval()
    if allow_random:
        print("WARNING: random weights, output is meaningless", file=sys.stderr)
        return model
    try:
        path = resolve_weights(spec)
        state = torch.load(path, map_location="cpu", weights_only=True)
    except Exception as err:  # noqa: BLE001 - message is the point
        raise SystemExit(WEIGHTS_HELP.format(spec=spec, err=err)) from err
    state = state.get("state_dict", state)
    # Checkpoint was saved from a DataParallel wrapper.
    state = {k.removeprefix("module."): v for k, v in state.items()}
    model.load_state_dict(state, strict=True)
    return model


# --------------------------------------------------------------------------
# GPU ops: colour conversion, mask rasterisation, blur
# --------------------------------------------------------------------------

# BT.601 limited range YUV -> BGR. Colour accuracy is irrelevant to the
# detector, and the blur itself never leaves YUV.
_YUV2BGR = torch.tensor(
    [
        [1.164383, 2.017232, 0.000000],  # B
        [1.164383, -0.391762, -0.812968],  # G
        [1.164383, 0.000000, 1.596027],  # R
    ]
)


def yuv_to_bgr_conv(dtype, device):
    """1x1 conv weights that do YUV->BGR, undo the limited-range offsets and
    subtract the detector mean in a single kernel."""
    m = _YUV2BGR
    bias = -(m @ torch.tensor([16.0, 128.0, 128.0])) - torch.tensor(BGR_MEAN)
    return (m.view(3, 3, 1, 1).to(device=device, dtype=dtype),
            bias.to(device=device, dtype=dtype))


def detector_input(y, u, v, size, weight, bias):
    """Full-res yuv420p planes -> (B, 3, dh, dw) BGR detector input.

    Planes are resized before conversion, so a full-resolution RGB tensor is
    never materialised.
    """
    yuv = torch.cat(
        [F.interpolate(p, size=size, mode="bilinear", align_corners=False)
         for p in (y, u, v)],
        dim=1,
    )
    return F.conv2d(yuv, weight, bias).contiguous(memory_format=torch.channels_last)


def rasterise_mask(boxes, keep, mh, mw, expand, device, dtype):
    """(B, K, 4) normalised boxes -> (B, 1, mh, mw) soft coverage mask.

    A superellipse (rounded rectangle) per box, max-reduced over K. Evaluated
    at frame/MASK_DOWNSCALE so the B*K*H*W broadcast stays cheap; the later
    bilinear upsample supplies the feathering.
    """
    xs = (torch.arange(mw, device=device, dtype=dtype) + 0.5) / mw
    ys = (torch.arange(mh, device=device, dtype=dtype) + 0.5) / mh
    cx = (boxes[..., 0] + boxes[..., 2]) * 0.5
    cy = (boxes[..., 1] + boxes[..., 3]) * 0.5
    rx = ((boxes[..., 2] - boxes[..., 0]) * 0.5 * expand).clamp_min(1e-4)
    ry = ((boxes[..., 3] - boxes[..., 1]) * 0.5 * expand).clamp_min(1e-4)
    dx = (xs.view(1, 1, 1, mw) - cx[..., None, None]) / rx[..., None, None]
    dy = (ys.view(1, 1, mh, 1) - cy[..., None, None]) / ry[..., None, None]
    dx2, dy2 = dx * dx, dy * dy
    dist = dx2 * dx2 + dy2 * dy2  # |dx|^4 + |dy|^4 == rounded rectangle
    m = ((1.0 - dist) * FEATHER_GAIN).clamp_(0.0, 1.0) * keep[..., None, None]
    return m.amax(dim=1, keepdim=True)


def blur_plane(plane, mask, strength):
    """Composite a decimation blur over `plane` where `mask` is non-zero.

    Cost is independent of face count: the whole plane is blurred and blended.
    Downsample-then-upsample genuinely destroys the information in the face
    region rather than merely smoothing it, which a Gaussian alone does not.
    """
    h, w = plane.shape[-2:]
    small = F.adaptive_avg_pool2d(plane, (max(1, h // strength), max(1, w // strength)))
    blurred = F.interpolate(small, size=(h, w), mode="bilinear", align_corners=False)
    m = F.interpolate(mask, size=(h, w), mode="bilinear", align_corners=False)
    return torch.lerp(plane, blurred, m)


def temporal_hold(mask, carry, hold):
    """Causal max-filter over the frame axis: a face detected at frame i keeps
    its mask for `hold` further frames.

    Cheap recall insurance against detector flicker, and it lets --stride skip
    detections without leaving gaps. Carries state across batches.
    """
    if hold <= 0:
        return mask, carry
    b, _, mh, mw = mask.shape
    if carry is None:
        carry = torch.zeros(hold, 1, mh, mw, device=mask.device, dtype=mask.dtype)
    history = torch.cat([carry, mask], dim=0)
    flat = history.view(1, 1, b + hold, mh * mw)
    out = F.max_pool2d(flat, kernel_size=(hold + 1, 1), stride=1).view(b, 1, mh, mw)
    return out, history[-hold:].clone()


# --------------------------------------------------------------------------
# Video I/O
# --------------------------------------------------------------------------


@dataclass
class VideoInfo:
    width: int
    height: int
    fps: float
    nframes: int | None


# Every subprocess call below runs ffmpeg with an explicit argv list and no
# shell, which is what this script exists to do (ruff S603).


def ffmpeg_exe() -> str:
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    import imageio_ffmpeg

    return imageio_ffmpeg.get_ffmpeg_exe()


def probe(path: str) -> VideoInfo:
    ffprobe = shutil.which("ffprobe")
    if ffprobe:
        out = subprocess.run(  # noqa: S603
            [ffprobe, "-v", "error", "-select_streams", "v:0", "-show_streams",
             "-of", "json", path],
            capture_output=True, text=True, check=True,
        ).stdout
        st = json.loads(out)["streams"][0]
        num, den = (st.get("avg_frame_rate") or "0/0").split("/")
        fps = float(num) / float(den) if float(den or 0) else 0.0
        if not fps:
            num, den = (st.get("r_frame_rate") or "25/1").split("/")
            fps = float(num) / float(den or 1)
        n = st.get("nb_frames")
        return VideoInfo(int(st["width"]), int(st["height"]), fps, int(n) if n else None)

    # No ffprobe (e.g. the imageio-ffmpeg wheel ships only ffmpeg): read the
    # stream description off ffmpeg's stderr banner instead.
    err = subprocess.run([ffmpeg_exe(), "-hide_banner", "-i", path],  # noqa: S603
                         capture_output=True, text=True).stderr
    line = next((x for x in err.splitlines() if "Stream #" in x and "Video:" in x), None)
    if line is None:
        raise RuntimeError(f"no video stream in {path}\n{err}")
    dims = re.search(r"(\d{2,5})x(\d{2,5})", line)
    rate = re.search(r"([\d.]+) fps", line)
    if not dims:
        raise RuntimeError(f"could not parse dimensions from: {line}")
    return VideoInfo(int(dims.group(1)), int(dims.group(2)),
                     float(rate.group(1)) if rate else 25.0, None)


def open_reader(path: str, info: VideoInfo, threads: int) -> subprocess.Popen:
    cmd = [ffmpeg_exe(), "-hide_banner", "-loglevel", "error", "-threads", str(threads),
           "-i", path, "-an", "-sn", "-f", "rawvideo", "-pix_fmt", "yuv420p"]
    if (info.width, info.height) != (info.width // 2 * 2, info.height // 2 * 2):
        cmd += ["-vf", f"scale={info.width // 2 * 2}:{info.height // 2 * 2}"]
    return subprocess.Popen(cmd + ["pipe:1"], stdout=subprocess.PIPE, bufsize=0)  # noqa: S603


def open_writer(src: str, dst: str, info: VideoInfo, preset: str, crf: int,
                threads: int) -> subprocess.Popen:
    cmd = [
        ffmpeg_exe(), "-hide_banner", "-loglevel", "error", "-y",
        "-f", "rawvideo", "-pix_fmt", "yuv420p",
        "-s", f"{info.width}x{info.height}", "-r", f"{info.fps:.6f}", "-i", "pipe:0",
        "-i", src,
        "-map", "0:v:0", "-map", "1:a?",
        "-c:v", "libx264", "-preset", preset, "-crf", str(crf),
        "-pix_fmt", "yuv420p", "-threads", str(threads),
        "-c:a", "copy", "-movflags", "+faststart", dst,
    ]
    return subprocess.Popen(cmd, stdin=subprocess.PIPE, bufsize=0)  # noqa: S603


def read_exact(stream, view: memoryview) -> int:
    """Fill `view` from `stream`; returns bytes read (short only at EOF)."""
    got = 0
    while got < len(view):
        n = stream.readinto(view[got:])
        if not n:
            break
        got += n
    return got


# --------------------------------------------------------------------------
# Pipeline
# --------------------------------------------------------------------------


def detector_size(width: int, height: int, long_side: int) -> tuple[int, int]:
    """Aspect-preserving detector resolution, both sides a multiple of 32.

    Keeping the source aspect ratio costs nothing and is ~40% cheaper than a
    square input for 16:9 material. Fixed per file, so CUDA graphs still apply.
    """
    def snap(x):
        return max(32, int(round(x / 32.0)) * 32)

    if width >= height:
        return snap(long_side * height / width), snap(long_side)
    return snap(long_side), snap(long_side * width / height)


class Detector:
    """Fixed-shape batched face detector returning normalised boxes + scores."""

    def __init__(self, model, size, device, dtype, topk, threshold, compile_mode):
        self.size, self.device, self.dtype = size, device, dtype
        self.topk, self.threshold = topk, threshold
        self.priors = prior_boxes(*size).to(device=device, dtype=torch.float32)
        self.weight, self.bias = yuv_to_bgr_conv(dtype, device)
        model = fuse_conv_bn(model).to(device=device, dtype=dtype)
        model = model.to(memory_format=torch.channels_last)
        self.model = torch.compile(model, mode=compile_mode) if compile_mode else model

    @torch.inference_mode()
    def __call__(self, y, u, v):
        x = detector_input(y, u, v, self.size, self.weight, self.bias)
        loc, score = self.model(x)
        # CUDA graphs reuse the output buffers; clone before the next call.
        loc, score = loc.float().clone(), score.float().clone()
        score, idx = score.topk(self.topk, dim=1)
        loc = loc.gather(1, idx[..., None].expand(-1, -1, 4))
        boxes = decode_boxes(loc, self.priors[idx.reshape(-1)].view(*idx.shape, 4))
        return boxes, (score > self.threshold).to(boxes.dtype)


class FrameIO:
    """ffmpeg decode -> pinned buffers -> caller -> pinned buffers -> ffmpeg encode.

    A reader and a writer thread keep both pipes busy while the GPU works.
    Buffers are recycled through free lists, so the steady state allocates
    nothing and every host<->device copy is asynchronous.
    """

    POOL = 4

    def __init__(self, args, info, batch: int, fbytes: int, cuda: bool):
        self.batch, self.fbytes, self.cuda = batch, fbytes, cuda
        self.reader = open_reader(args.input, info, args.decode_threads)
        self.writer = open_writer(args.input, args.output, info, args.preset,
                                  args.crf, args.encode_threads)
        self.limit = args.limit_frames or (1 << 62)
        self.errors: list[BaseException] = []
        self.inflight: list = []

        def buf():
            b = torch.empty((batch, fbytes), dtype=torch.uint8)
            return b.pin_memory() if cuda else b

        self.free_in, self.in_q = queue.Queue(), queue.Queue(maxsize=2)
        self.free_out, self.out_q = queue.Queue(), queue.Queue(maxsize=2)
        for _ in range(self.POOL):
            self.free_in.put(buf())
            self.free_out.put(buf())
        self.threads = [threading.Thread(target=self._read, daemon=True),
                        threading.Thread(target=self._write, daemon=True)]
        for t in self.threads:
            t.start()

    def _view(self, buf, frames):
        return memoryview(buf.numpy()).cast("B")[: frames * self.fbytes]

    def _read(self):
        try:
            remaining = self.limit
            while remaining > 0:
                buf = self.free_in.get()
                want = min(self.batch, remaining)
                got = read_exact(self.reader.stdout, self._view(buf, want)) // self.fbytes
                remaining -= got
                self.in_q.put((buf, got))
                if got < want:
                    break
        except BaseException as e:  # noqa: BLE001 - re-raised on the main thread
            self.errors.append(e)
        finally:
            self.in_q.put((None, 0))

    def _write(self):
        try:
            while True:
                item = self.out_q.get()
                if item is None:
                    break
                buf, event, n = item
                if event is not None:
                    event.synchronize()
                self.writer.stdin.write(self._view(buf, n))
                self.free_out.put(buf)
        except BaseException as e:  # noqa: BLE001
            self.errors.append(e)

    def batches(self):
        """Yields (host buffer, frames filled) until the decoder runs dry."""
        while True:
            buf, n = self.in_q.get()
            if buf is None or n == 0:
                return
            yield buf, n

    def recycle(self, buf):
        """Return an input buffer once its upload has landed."""
        if not self.cuda:
            self.free_in.put(buf)
            return
        event = torch.cuda.Event()
        event.record()
        self.inflight.append((buf, event))
        while self.inflight and self.inflight[0][1].query():
            self.free_in.put(self.inflight.pop(0)[0])

    def write(self, out: torch.Tensor, n: int) -> None:
        buf = self.free_out.get()
        buf.copy_(out, non_blocking=self.cuda)
        event = None
        if self.cuda:
            event = torch.cuda.Event()
            event.record()
        self.out_q.put((buf, event, n))

    def close(self) -> None:
        self.out_q.put(None)
        for t in self.threads:
            t.join(timeout=60)
        for b, _ in self.inflight:
            self.free_in.put(b)
        if self.writer.stdin:
            self.writer.stdin.close()
        self.writer.wait()
        # Stopping early (--limit-frames) leaves the decoder mid-stream. Kill it
        # rather than let it try to flush into a pipe nobody is reading.
        if self.reader.poll() is None:
            self.reader.kill()
        self.reader.stdout.close()
        self.reader.wait()
        if self.errors:
            raise self.errors[0]


def process(args) -> None:
    device = torch.device(args.device)
    cuda = device.type == "cuda"
    dtype = torch.float16 if cuda else torch.float32
    if cuda:
        torch.backends.cudnn.benchmark = True
        torch.backends.cuda.matmul.allow_tf32 = True

    info = probe(args.input)
    info.width, info.height = info.width // 2 * 2, info.height // 2 * 2
    size = detector_size(info.width, info.height, args.det_size)
    batch = args.batch - args.batch % args.stride or args.stride
    ysz = info.width * info.height
    csz = ysz // 4
    fbytes = ysz + 2 * csz
    half = (info.height // 2, info.width // 2)
    mh, mw = max(1, info.height // MASK_DOWNSCALE), max(1, info.width // MASK_DOWNSCALE)

    print(f"{Path(args.input).name}: {info.width}x{info.height} @ {info.fps:.2f} fps"
          f" | detector {size[1]}x{size[0]} | batch {batch} stride {args.stride}",
          file=sys.stderr)

    det = Detector(build_model(args.weights, args.allow_random), size, device, dtype,
                   args.topk, args.threshold,
                   args.compile_mode if cuda and not args.no_compile else None)
    io = FrameIO(args, info, batch, fbytes, cuda)

    carry, done = None, 0
    start = time.perf_counter()
    try:
        for buf, n in io.batches():
            gpu = buf.to(device, non_blocking=cuda)
            io.recycle(buf)

            y = gpu[:, :ysz].to(dtype).reshape(batch, 1, info.height, info.width)
            u = gpu[:, ysz:ysz + csz].to(dtype).reshape(batch, 1, *half)
            v = gpu[:, ysz + csz:].to(dtype).reshape(batch, 1, *half)

            s = args.stride
            boxes, keep = det(y[::s], u[::s], v[::s])
            mask = rasterise_mask(boxes, keep, mh, mw, args.expand, device, torch.float32)
            if s > 1:
                mask = mask.repeat_interleave(s, dim=0)[:batch]
            mask, carry = temporal_hold(mask.to(dtype), carry, args.hold)

            out = torch.empty((batch, fbytes), dtype=torch.uint8, device=device)
            for plane, dst, sz in ((y, out[:, :ysz], ysz),
                                   (u, out[:, ysz:ysz + csz], csz),
                                   (v, out[:, ysz + csz:], csz)):
                blurred = blur_plane(plane, mask, args.strength)
                dst.copy_(blurred.clamp_(0, 255).reshape(batch, sz).to(torch.uint8))

            io.write(out, n)
            done += n
            if args.progress and done % (batch * 20) == 0:
                rate = done / (time.perf_counter() - start)
                print(f"  {done} frames  {rate:8.1f} fps", file=sys.stderr)
    finally:
        io.close()

    rate = done / max(time.perf_counter() - start, 1e-9)
    print(f"{done} frames in {time.perf_counter() - start:.1f}s = {rate:.1f} fps "
          f"({rate / max(info.fps, 1e-9):.1f}x realtime)", file=sys.stderr)


# --------------------------------------------------------------------------
# Benchmark
# --------------------------------------------------------------------------


def benchmark(args) -> None:
    """Measure detector latency/throughput on synthetic frames.

    Reports the numbers the deployment estimate depends on: batch-1 latency
    (the ~1 ms target) and saturated batched throughput.
    """
    device = torch.device(args.device)
    cuda = device.type == "cuda"
    dtype = torch.float16 if cuda else torch.float32
    if cuda:
        torch.backends.cudnn.benchmark = True
        print(torch.cuda.get_device_name(0), file=sys.stderr)

    w, h = (args.bench_width, args.bench_height)
    size = detector_size(w, h, args.det_size)
    model = build_model(args.weights, args.allow_random)
    print(f"frame {w}x{h} -> detector {size[1]}x{size[0]}", file=sys.stderr)
    print(f"{'batch':>6} {'ms/batch':>10} {'ms/frame':>10} {'fps':>10}", file=sys.stderr)

    for batch in args.bench_batches:
        det = Detector(model, size, device, dtype, args.topk, args.threshold,
                       args.compile_mode if cuda and not args.no_compile else None)
        y = torch.randint(0, 255, (batch, 1, h, w), device=device).to(dtype)
        u = torch.randint(0, 255, (batch, 1, h // 2, w // 2), device=device).to(dtype)
        v = torch.randint_like(u, 0, 255)
        mh, mw = max(1, h // MASK_DOWNSCALE), max(1, w // MASK_DOWNSCALE)

        def step(det=det, y=y, u=u, v=v, mh=mh, mw=mw):
            boxes, keep = det(y, u, v)
            mask = rasterise_mask(boxes, keep, mh, mw, args.expand, device, torch.float32)
            if args.bench_full:
                m = mask.to(dtype)
                for plane in (y, u, v):
                    blur_plane(plane, m, args.strength)

        for _ in range(args.bench_warmup):
            step()
        if cuda:
            torch.cuda.synchronize()

        times = []
        for _ in range(args.bench_iters):
            t0 = time.perf_counter()
            step()
            if cuda:
                torch.cuda.synchronize()
            times.append(time.perf_counter() - t0)

        ms = statistics.median(times) * 1e3
        print(f"{batch:>6} {ms:>10.3f} {ms / batch:>10.4f} {batch / (ms / 1e3):>10.1f}",
              file=sys.stderr)


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def main(argv=None) -> None:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("input", nargs="?", help="input mp4")
    p.add_argument("output", nargs="?", help="output mp4")

    g = p.add_argument_group("detector")
    g.add_argument("--weights", default=os.environ.get("FACE_BLUR_WEIGHTS", DEFAULT_WEIGHTS),
                   help="path, http(s) URL, or hf:REPO_ID:FILENAME")
    g.add_argument("--allow-random", action="store_true",
                   help="run with untrained weights (benchmarking only)")
    g.add_argument("--det-size", type=int, default=640,
                   help="detector long side, multiple of 32 (default: 640)")
    g.add_argument("--threshold", type=float, default=0.35,
                   help="score threshold; low favours recall, and a false "
                        "positive only blurs some background (default: 0.35)")
    g.add_argument("--topk", type=int, default=64,
                   help="max faces per frame. NMS is skipped -- duplicate boxes "
                        "union into the same mask (default: 64)")

    g = p.add_argument_group("blur")
    g.add_argument("--expand", type=float, default=1.3,
                   help="box scale before rasterising (default: 1.3)")
    g.add_argument("--strength", type=int, default=12,
                   help="decimation factor inside the mask (default: 12)")
    g.add_argument("--hold", type=int, default=2,
                   help="keep each mask for N further frames (default: 2)")

    g = p.add_argument_group("throughput")
    g.add_argument("--batch", type=int, default=32)
    g.add_argument("--stride", type=int, default=1,
                   help="detect every Nth frame, reuse the mask between "
                        "(2-3 is nearly free with --hold; default: 1)")
    g.add_argument("--device", default="cuda" if torch.cuda.is_available() else "cpu")
    g.add_argument("--compile-mode", default="reduce-overhead",
                   help="torch.compile mode; reduce-overhead enables CUDA graphs")
    g.add_argument("--no-compile", action="store_true")
    g.add_argument("--decode-threads", type=int, default=4)
    g.add_argument("--encode-threads", type=int, default=8)
    g.add_argument("--preset", default="veryfast", help="x264 preset (default: veryfast)")
    g.add_argument("--crf", type=int, default=23)
    g.add_argument("--limit-frames", type=int, default=0)
    g.add_argument("--progress", action="store_true")

    g = p.add_argument_group("benchmark")
    g.add_argument("--benchmark", action="store_true")
    g.add_argument("--bench-batches", type=int, nargs="+", default=[1, 4, 16, 32, 64])
    g.add_argument("--bench-width", type=int, default=1280)
    g.add_argument("--bench-height", type=int, default=720)
    g.add_argument("--bench-iters", type=int, default=50)
    g.add_argument("--bench-warmup", type=int, default=20)
    g.add_argument("--bench-full", action="store_true",
                   help="include mask + blur, not just the detector")

    args = p.parse_args(argv)
    if args.benchmark:
        benchmark(args)
        return
    if not args.input or not args.output:
        p.error("input and output are required unless --benchmark is given")
    process(args)


if __name__ == "__main__":
    main()
