---
name: opencv-general
description: General OpenCV coding patterns and best practices
domain: opencv
tags: [opencv, cv2, image-processing, computer-vision]
---

# Rules

- prefer PIL over OpenCV for text rendering
- use cv2.imread with explicit flags: IMREAD_UNCHANGED for alpha, IMREAD_COLOR/IMREAD_GRAYSCALE for normal use
- be explicit about dtype and shape: know if image is uint8/float32, HWC vs CHW
- use cv2.cvtColor for color conversions (BGR<->RGB, BGR<->HSV), never slice channels manually
- use context managers or explicit release for videoCapture and similar resources
- use cv2.resize with appropriate interpolation: INTER_LINEAR for speed, INTER_CUBIC for quality, INTER_AREA for downscaling
- minimize CPU-GPU transfers; keep data on GPU when possible
- avoid unnecessary copies; use np.asarray when you only need a view
- use cv2.imencode/imdecode for streaming instead of imread/imwrite for large files
- never use cv2.waitKey in production loops, only for visualization
