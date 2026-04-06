#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["easyocr"]
# ///

"""Extract text and coordinates from an image using EasyOCR."""

import argparse
import json
import sys

import easyocr


def main():
    parser = argparse.ArgumentParser(description="Extract text from an image")
    parser.add_argument("image", help="Path to image file")
    parser.add_argument("--find", help="Filter results by substring (case-insensitive)")
    parser.add_argument("--text-only", action="store_true", help="Output plain text only")
    parser.add_argument("--lang", default="en", help="Language code (default: en)")
    args = parser.parse_args()

    reader = easyocr.Reader([args.lang], gpu=False, verbose=False)
    results = reader.readtext(args.image)

    entries = []
    for bbox, text, confidence in results:
        # bbox is [[x1,y1], [x2,y2], [x3,y3], [x4,y4]] (four corners)
        xs = [p[0] for p in bbox]
        ys = [p[1] for p in bbox]
        x = int(min(xs))
        y = int(min(ys))
        w = int(max(xs) - min(xs))
        h = int(max(ys) - min(ys))
        entries.append({
            "text": text,
            "x": x,
            "y": y,
            "w": w,
            "h": h,
            "cx": x + w // 2,
            "cy": y + h // 2,
            "confidence": round(float(confidence), 4),
        })

    # Filter by --find
    if args.find:
        needle = args.find.lower()
        entries = [e for e in entries if needle in e["text"].lower()]

    # Output
    if args.text_only:
        for e in entries:
            print(e["text"])
    else:
        json.dump(entries, sys.stdout, indent=2)
        print()


if __name__ == "__main__":
    main()
