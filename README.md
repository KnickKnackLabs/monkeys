<div align="center">

<img src="logo.jpg" alt="monkeys logo" width="256">

# monkeys

**Media from the command line — images, speech, transcription, and OCR.**

[![tasks: mise](https://img.shields.io/badge/tasks-mise-7c3aed?style=flat)](https://mise.jdx.dev)
[![runtime: uv + Python](https://img.shields.io/badge/runtime-uv%20%2B%20Python-de5fe9?style=flat)](https://docs.astral.sh/uv/)
[![tests: 12 passing](https://img.shields.io/badge/tests-12%20passing-blue?style=flat)](https://bats-core.readthedocs.io)

</div>

## Install

```bash
shiv install monkeys

# Or manually:
git clone https://github.com/KnickKnackLabs/monkeys.git ~/monkeys
cd ~/monkeys && mise trust && mise install
eval "$(mise -C ~/monkeys run -q shell)"
```

## Usage

```bash
# Image generation (requires HF_TOKEN)
monkeys generate "a cartoon monkey"
monkeys generate "pixel art sunset" -o sunset.png

# Text-to-speech (local, no token needed)
monkeys speak "Hello world"
monkeys speak "Good morning" --voice af_bella --play

# Speech-to-text (local, requires ffmpeg)
monkeys listen recording.wav
monkeys listen --record -d 5

# OCR — extract text and coordinates from images
monkeys ocr screenshot.png                    # JSON with bounding boxes
monkeys ocr screenshot.png --find "Select"    # Filter by substring
monkeys ocr screenshot.png --text-only        # Plain text output
```

> [!NOTE]
> OCR runs locally via EasyOCR — no API key needed. First run downloads models (~50MB).

## OCR output

Default output is JSON with bounding box coordinates, useful for automation (e.g. driving a VM via screenshot → OCR → click):

```json
[
  {
    "text": "Select",
    "x": 1029, "y": 681, "w": 40, "h": 16,
    "cx": 1049, "cy": 689,
    "confidence": 0.9987
  }
]
```

`cx`/`cy` are the center of the bounding box — the click target.

## Configuration

Set `HF_TOKEN` for Hugging Face API authentication (image generation only):

```bash
export HF_TOKEN="hf_your_token_here"  # https://huggingface.co/settings/tokens
```

## Testing

```bash
mise run test
```

12 BATS tests. OCR tests use real EasyOCR against a generated fixture image.
