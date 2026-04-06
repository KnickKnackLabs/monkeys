# /// script
# dependencies = ["Pillow"]
# ///

"""Generate the OCR test fixture image.

Run with: uv run test/fixtures/generate.py
Output: test/fixtures/test-ocr.png
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FIXTURE_DIR = Path(__file__).parent
OUTPUT = FIXTURE_DIR / "test-ocr.png"

img = Image.new("RGB", (800, 400), "white")
draw = ImageDraw.Draw(img)

# Use a readable font size for reliable OCR detection
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 36)
except (IOError, OSError):
    font = ImageFont.load_default(size=36)

draw.text((50, 50), "Hello World", fill="black", font=font)
draw.text((50, 150), "Select", fill="blue", font=font)
draw.text((50, 250), "Cancel", fill="red", font=font)

img.save(OUTPUT)
print(f"Generated {OUTPUT}")
