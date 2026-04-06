#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["Pillow"]
# ///

"""Generate the OCR test fixture image.

Run with: uv run test/fixtures/generate.py
Output: test/fixtures/test-ocr.png

Uses Pillow's built-in default font at size 36 for portability across
macOS, Linux, and CI (no system font dependencies).
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FIXTURE_DIR = Path(__file__).parent
OUTPUT = FIXTURE_DIR / "test-ocr.png"

img = Image.new("RGB", (800, 400), "white")
draw = ImageDraw.Draw(img)

# Use Pillow's built-in font — no system font dependency.
# load_default(size=N) requires Pillow >= 10.1.0.
font = ImageFont.load_default(size=36)

draw.text((50, 50), "Hello World", fill="black", font=font)
draw.text((50, 150), "Select", fill="blue", font=font)
draw.text((50, 250), "Cancel", fill="red", font=font)

img.save(OUTPUT)
print(f"Generated {OUTPUT}")
