#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "torch==2.14.0",
#     "numpy==2.5.2",
#     "imageio-ffmpeg==0.6.0",
#     "huggingface-hub==1.30.0",
#     "pytest==9.0.1",
# ]
# [tool.uv]
# exclude-newer = "2026-09-04T00:00:00Z"
# ///
# ruff: noqa: S603 - every subprocess call here is ffmpeg with a literal argv
"""Checks that do not need a GPU or the pretrained checkpoint.

    uv run test_face_blur.py

The architecture test is the important one: it pins the parameter names and
shapes against the released `mobilenet0.25_Final.pth`, which the CI box cannot
download. If it passes, load_state_dict(strict=True) will too.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

import pytest
import torch

sys.path.insert(0, str(Path(__file__).parent))
import face_blur as fb  # noqa: E402

# Name -> shape, transcribed from biubug6/Pytorch_Retinaface cfg_mnet.
CHECKPOINT_SPOT_CHECKS = {
    "body.stage1.0.0.weight": (8, 3, 3, 3),
    "body.stage1.0.1.running_mean": (8,),
    "body.stage1.1.0.weight": (8, 1, 3, 3),
    "body.stage1.1.3.weight": (16, 8, 1, 1),
    "body.stage2.0.3.weight": (128, 64, 1, 1),
    "body.stage3.1.3.weight": (256, 256, 1, 1),
    "fpn.output1.0.weight": (64, 64, 1, 1),
    "fpn.output3.0.weight": (64, 256, 1, 1),
    "fpn.merge1.0.weight": (64, 64, 3, 3),
    "ssh1.conv3X3.0.weight": (32, 64, 3, 3),
    "ssh1.conv5X5_1.0.weight": (16, 64, 3, 3),
    "ssh1.conv7x7_3.0.weight": (16, 16, 3, 3),
    "ClassHead.0.conv1x1.weight": (4, 64, 1, 1),
    "BboxHead.0.conv1x1.weight": (8, 64, 1, 1),
    "LandmarkHead.0.conv1x1.weight": (20, 64, 1, 1),
}


def test_state_dict_matches_released_checkpoint():
    state = fb.RetinaFace().state_dict()
    for name, shape in CHECKPOINT_SPOT_CHECKS.items():
        assert name in state, f"missing {name}"
        assert tuple(state[name].shape) == shape, name
    assert len(state) == 300


def test_priors_match_head_output():
    size = fb.detector_size(1280, 720, 640)
    model = fb.RetinaFace().eval()
    with torch.inference_mode():
        loc, score = model(torch.zeros(1, 3, *size))
    assert loc.shape[1] == fb.prior_boxes(*size).shape[0] == score.shape[1]


def test_decode_recovers_the_prior_when_offsets_are_zero():
    priors = fb.prior_boxes(*fb.detector_size(1280, 720, 640))
    boxes = fb.decode_boxes(torch.zeros(1, priors.shape[0], 4), priors)[0]
    cx, cy = (boxes[:, 0] + boxes[:, 2]) / 2, (boxes[:, 1] + boxes[:, 3]) / 2
    torch.testing.assert_close(cx, priors[:, 0])
    torch.testing.assert_close(cy, priors[:, 1])
    torch.testing.assert_close(boxes[:, 2] - boxes[:, 0], priors[:, 2])


def test_conv_bn_fusion_preserves_output():
    torch.manual_seed(0)
    model = fb.RetinaFace().eval()
    # Random BN stats: with the init defaults, fusion is trivially exact.
    for m in model.modules():
        if isinstance(m, torch.nn.BatchNorm2d):
            m.running_mean.normal_()
            m.running_var.uniform_(0.5, 2.0)
            m.weight.data.normal_(1.0, 0.1)
            m.bias.data.normal_()
    x = torch.randn(2, 3, 96, 160)
    with torch.inference_mode():
        before = model(x)
        after = fb.fuse_conv_bn(model)(x)
    assert not any(isinstance(m, torch.nn.BatchNorm2d) for m in model.modules())
    for a, b in zip(before, after):
        torch.testing.assert_close(a, b, rtol=1e-4, atol=1e-4)


def test_mask_covers_the_box_and_nothing_else():
    boxes = torch.tensor([[[0.25, 0.25, 0.45, 0.45]]])
    keep = torch.ones(1, 1)
    m = fb.rasterise_mask(boxes, keep, 90, 160, 1.0, torch.device("cpu"), torch.float32)
    assert m[0, 0, 31, 56] == pytest.approx(1.0)  # box centre
    assert m[0, 0, 5, 5] == 0.0  # far corner
    assert m.max() == pytest.approx(1.0)
    # A superellipse inscribed in the box covers most of it, not all of it.
    inside = m[0, 0, 23:40, 40:72].mean()
    assert 0.75 < inside < 1.0


def test_low_scoring_boxes_are_dropped():
    boxes = torch.tensor([[[0.25, 0.25, 0.45, 0.45], [0.7, 0.7, 0.9, 0.9]]])
    m = fb.rasterise_mask(boxes, torch.tensor([[1.0, 0.0]]), 90, 160, 1.0,
                          torch.device("cpu"), torch.float32)
    assert m[0, 0, 31, 56] == pytest.approx(1.0)
    assert m[0, 0, 72, 128] == 0.0


def test_blur_destroys_detail_only_inside_the_mask():
    torch.manual_seed(0)
    plane = (torch.rand(1, 1, 360, 640) * 255)
    mask = torch.zeros(1, 1, 45, 80)
    mask[..., :22, :] = 1.0  # top half
    out = fb.blur_plane(plane, mask, 12)
    top_in, top_out = plane[..., :150, :].std(), out[..., :150, :].std()
    bot_in, bot_out = plane[..., 250:, :].std(), out[..., 250:, :].std()
    assert top_out < top_in * 0.2, "masked region was not blurred"
    torch.testing.assert_close(bot_out, bot_in)


def test_temporal_hold_extends_a_detection_forward_only():
    mask = torch.zeros(6, 1, 4, 4)
    mask[2] = 1.0
    out, carry = fb.temporal_hold(mask, None, hold=2)
    assert [float(f.max()) for f in out] == [0, 0, 1, 1, 1, 0]
    assert carry.shape[0] == 2


def test_temporal_hold_carries_across_batches():
    a, b = torch.zeros(4, 1, 4, 4), torch.zeros(4, 1, 4, 4)
    a[3] = 1.0
    _, carry = fb.temporal_hold(a, None, hold=2)
    out, _ = fb.temporal_hold(b, carry, hold=2)
    assert [float(f.max()) for f in out] == [1, 1, 0, 0]


def _synthetic_mp4(path: Path, seconds=2, fps=25, size="320x240"):
    subprocess.run(
        [fb.ffmpeg_exe(), "-hide_banner", "-loglevel", "error", "-y",
         "-f", "lavfi", "-i", f"testsrc=size={size}:rate={fps}:duration={seconds}",
         "-f", "lavfi", "-i", f"sine=frequency=440:duration={seconds}",
         "-c:v", "libx264", "-preset", "ultrafast", "-pix_fmt", "yuv420p",
         "-c:a", "aac", str(path)],
        check=True,
    )


def test_probe_reads_dimensions_and_rate():
    with tempfile.TemporaryDirectory() as d:
        src = Path(d) / "in.mp4"
        _synthetic_mp4(src, seconds=1, fps=30, size="640x360")
        info = fb.probe(str(src))
    assert (info.width, info.height) == (640, 360)
    assert info.fps == pytest.approx(30.0, abs=0.01)


def test_end_to_end_preserves_geometry_and_audio():
    with tempfile.TemporaryDirectory() as d:
        src, dst = Path(d) / "in.mp4", Path(d) / "out.mp4"
        _synthetic_mp4(src)
        fb.main([str(src), str(dst), "--device", "cpu", "--allow-random",
                 "--batch", "8", "--det-size", "160", "--no-compile"])
        assert dst.stat().st_size > 0
        info = fb.probe(str(dst))
        assert (info.width, info.height) == (320, 240)
        assert info.fps == pytest.approx(25.0, abs=0.01)
        err = subprocess.run([fb.ffmpeg_exe(), "-hide_banner", "-i", str(dst)],
                             capture_output=True, text=True).stderr
        assert "Audio:" in err, "audio stream was dropped"

        n = subprocess.run(
            [fb.ffmpeg_exe(), "-hide_banner", "-loglevel", "error", "-i", str(dst),
             "-f", "null", "-"], capture_output=True, text=True)
        assert n.returncode == 0, n.stderr


def test_random_weights_leave_the_picture_alone():
    """Sanity guard: untrained weights must not silently blur the whole frame."""
    with tempfile.TemporaryDirectory() as d:
        src, dst = Path(d) / "in.mp4", Path(d) / "out.mp4"
        _synthetic_mp4(src, seconds=1)
        fb.main([str(src), str(dst), "--device", "cpu", "--allow-random",
                 "--batch", "8", "--det-size", "160", "--no-compile",
                 "--threshold", "0.999999"])
        raw = subprocess.run(
            [fb.ffmpeg_exe(), "-hide_banner", "-loglevel", "error", "-i", str(dst),
             "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "gray", "-"],
            capture_output=True, check=True).stdout
        y = torch.frombuffer(bytearray(raw), dtype=torch.uint8).float()
        assert y.std() > 40, "frame looks flat; blur was applied everywhere"


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v", "--tb=short", "-x"]))
