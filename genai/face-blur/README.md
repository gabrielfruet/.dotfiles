# face_blur

mp4 in, mp4 out, faces blurred. One PyTorch script with its dependencies pinned
in a PEP 723 header and resolved in `face_blur.py.lock`.

```sh
uv run face_blur.py in.mp4 out.mp4                 # or ./face_blur.py, it is executable
uv run face_blur.py --benchmark --allow-random     # latency/throughput sweep
uv run test_face_blur.py                           # 12 checks, no GPU needed
```

Weights are `mobilenet0.25_Final.pth` from biubug6/Pytorch_Retinaface (1.7 MB).
The script fetches them from a Hugging Face mirror; override with `--weights`,
which takes a path, an `http(s)` URL, or `hf:REPO_ID:FILENAME`.

## Detector

RetinaFace on a MobileNetV1-0.25 backbone, ~1 GFLOP per frame at 640x352.
WIDER FACE AP is 90.7/88.2/73.8 on easy/medium/hard. The ResNet-50 variant of
the same model costs ~40x the FLOPs and buys ~16 points on the hard set. For
anonymisation a missed face costs more than a soft box, so that budget goes into
recall settings instead of a bigger backbone.

Speed comes from six choices:

- Conv+BN is folded before inference. A depthwise-separable backbone is
  dominated by launch overhead, so deleting ~50 BatchNorm kernels matters more
  here than it would on a large model. `test_conv_bn_fusion_preserves_output`
  pins the numerics.
- CUDA graphs, through `torch.compile(mode="reduce-overhead")`. The net is ~60
  tiny kernels, and replaying them as one graph is the largest single win at
  small batch. Shapes are fixed per file, and the last partial batch is padded
  so nothing recompiles.
- No NMS. Overlapping boxes union into the same mask, so duplicate detections
  are free. `topk(64)` replaces NMS with a fixed-shape op, which keeps the graph
  static and takes a host synchronisation out of the inner loop.
- No Python loop over faces. Every box rasterises at once as a superellipse
  broadcast over a frame/8 grid, max-reduced over the box axis. Bilinear
  upsampling back to full resolution supplies the feathered edge for free.
- Blur cost independent of face count. The whole plane is decimated by
  `--strength` and upsampled, then `lerp`ed against the original under the mask.
  A 12x downsample genuinely destroys the information in the face region; a
  Gaussian of comparable visual strength leaves much of it recoverable.
- yuv420p end to end. Frames cross the pipe and PCIe at 1.5 bytes/px instead of
  3, and the blur runs directly on the Y/U/V planes. RGB exists only at detector
  resolution: Y, U and V are resized first, then converted by a single 1x1
  convolution that also folds in the limited-range offsets and the mean
  subtraction.

Two knobs trade recall against cost. `--hold N` keeps each mask alive for N
further frames as a causal max-filter, which covers detector flicker and costs
nothing. `--stride N` runs detection on every Nth frame; with `--hold` and
`--expand` covering the gap, `--stride 2` roughly halves detector time.

## Throughput budget, one A100 40GB, 720p

Per-stage ceilings, not measurements. The point is which one binds.

| stage | limit | ceiling |
| --- | --- | --- |
| detector, fp16 + CUDA graphs | ~1 GFLOP/frame at ~10% of 312 TFLOPS | 10-30k fps |
| mask, blur, resize | ~35 MB/frame against 1.5 TB/s HBM | ~35k fps |
| PCIe 4.0 x16, yuv420p both ways | 1.38 MB/frame per direction | ~18k fps |
| H.264 decode, CPU | ~600 fps/core at 720p | 600 x cores |
| H.264 decode, NVDEC | 5 engines on A100 | few thousand fps |
| H.264 encode, x264 `ultrafast` | ~350 fps/core at 720p | 350 x cores |
| H.264 encode, NVENC | **A100 has no NVENC** | 0 |

GA100 shipped with 5 NVDEC engines and no encoder, so every output frame is
encoded on the CPU. That is the binding constraint, and what fixes it is vCPU
provisioning. On 32 vCPU, spending ~8 cores on decode and ~22 on `ultrafast`
encode puts the node at roughly **5,000 fps sustained at 720p**. Moving decode
to NVDEC frees the whole CPU for encoding and pushes that toward 8,000. At
1080p, divide by ~2.25.

The detector is not the bottleneck in any configuration. Feeding it perfectly
would finish the job in about a third of the time the encoders need.

## 1,000 hours

At 25 fps that is 90M frames; at 30 fps, 108M. Wall-clock on one node:

| sustained fps | 90M frames | 108M frames |
| --- | --- | --- |
| 2,000 | 12.5 h | 15.0 h |
| 3,000 | 8.3 h | 10.0 h |
| **5,000** | **5.0 h** | **6.0 h** |
| 8,000 | 3.1 h | 3.8 h |
| 12,000 | 2.1 h | 2.5 h |

So: **5-6 hours on one well-provisioned A100 node**, under an hour on eight.
Sharding is by file, so scaling is linear until the storage backend complains.
At $1-4 per GPU-hour depending on provider, the GPU bill for the whole corpus
lands somewhere between $10 and $25 — the vCPU count attached to that GPU
matters more to the total than the GPU does.

Source I/O is undemanding: 1,000 h of 720p at 3 Mbit/s is ~1.35 TB, read over
six hours at ~65 MB/s.

## Running it at scale

Shard by file, one worker per file, 6-10 workers per GPU with CUDA MPS enabled:

```sh
nvidia-cuda-mps-control -d
find /corpus -name '*.mp4' -print0 |
  xargs -0 -P 8 -n 1 sh -c \
    './face_blur.py "$1" "/out/$(basename "$1")" --stride 2 --preset ultrafast' sh
```

Triton Inference Server is the wrong tool for this job. It earns its keep when
many clients share a model online; here it would put gRPC serialisation in front
of exactly the frame traffic the yuv420p path exists to minimise, and it does
nothing for the encoders that actually bind. If you want it anyway, put only the
detector behind it (`instance_group { count: 4, kind: KIND_GPU }`, dynamic
batching with a ~2 ms queue delay) and keep decode, blur and encode in the
client. Separately: `torch.compile` already lowers the mask and blur ops to
OpenAI Triton kernels, so there is no second pass to make there.

## Latency

`--benchmark` reports batch-1 latency and the batched throughput curve:

```sh
uv run face_blur.py --benchmark --bench-batches 1 4 16 32 64
uv run face_blur.py --benchmark --bench-full     # add mask + blur
```

Batch 1 at 640x352 with CUDA graphs should land near 1 ms. That number does not
set throughput — 5,000 fps comes from batching, not from 1/latency — but it is
the right check that the graph capture and the fp16 path are live.

## Tuning for quality

`--threshold 0.35` is deliberately low. A false positive blurs some background;
a false negative is a compliance incident. `--expand 1.3` grows each box before
rasterising, since an ellipse inscribed in a tight face box clips chin and ears.

Validate on a sample of the real corpus, not on WIDER FACE, and measure missed
faces per thousand frames rather than mAP. If wide shots or crowds are common,
raise `--det-size` to 800 or 1024 before reaching for a heavier detector; the
backbone is cheap enough that resolution buys more recall per millisecond.

## Not verified here

- **The default weights URL.** The sandbox this was written in blocks Hugging
  Face, so the mirror is unconfirmed. `test_state_dict_matches_released_checkpoint`
  pins all 300 parameter names and shapes against the released checkpoint, so if
  the file is the right one it loads with `strict=True`; if the mirror is wrong,
  `--weights` takes any path or URL.
- **Every A100 number above.** No GPU was available. They are arithmetic on
  published bandwidths and FLOPs, with the utilisation assumptions stated.
  `--benchmark` replaces them with measurements in about a minute.
- **Detection quality.** Tested with random weights only, which exercises the
  plumbing but says nothing about recall.
