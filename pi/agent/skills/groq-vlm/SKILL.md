---
name: groq-vlm
description: Analyze images with Groq VLM (Llama 4 Scout). Use when you need visual understanding—screenshots, UI feedback, image descriptions.
---

# Groq VLM

Send images to Groq's vision model for analysis.

## Usage

    ./groq-vlm.sh <image_path> [prompt]

## Setup

Requires `GROQ_API_KEY` environment variable.

## Examples

    ./groq-vlm.sh screenshot.png
    ./groq-vlm.sh screenshot.png "What issues do you see?"
