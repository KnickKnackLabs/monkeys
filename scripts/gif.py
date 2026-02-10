# /// script
# dependencies = ["Pillow"]
# ///

import argparse
import math
from PIL import Image, ImageDraw, ImageFont


def typewriter(text, width, height, fps, duration, bg, fg, font_size):
    """Characters appear one by one."""
    frames = []
    total_frames = int(fps * duration)
    font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", font_size)

    for i in range(total_frames):
        img = Image.new("RGBA", (width, height), bg)
        draw = ImageDraw.Draw(img)
        # How many characters to show at this frame
        chars = int((i / max(total_frames - 1, 1)) * len(text)) + 1
        chars = min(chars, len(text))
        partial = text[:chars]
        # Center the full text, but only draw partial
        bbox = font.getbbox(text)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        x = (width - text_w) // 2
        y = (height - text_h) // 2
        draw.text((x, y), partial, fill=fg, font=font)
        frames.append(img)

    # Hold the final frame for a beat
    for _ in range(max(fps // 2, 1)):
        frames.append(frames[-1].copy())

    return frames


def bounce(text, width, height, fps, duration, bg, fg, font_size):
    """Text bounces vertically."""
    frames = []
    total_frames = int(fps * duration)
    font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", font_size)
    bbox = font.getbbox(text)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (width - text_w) // 2
    amplitude = (height - text_h) // 4

    for i in range(total_frames):
        img = Image.new("RGBA", (width, height), bg)
        draw = ImageDraw.Draw(img)
        t = i / max(total_frames - 1, 1)
        y_offset = int(amplitude * abs(math.sin(t * math.pi * 2)))
        y = (height - text_h) // 2 - y_offset
        draw.text((x, y), text, fill=fg, font=font)
        frames.append(img)

    return frames


def scroll(text, width, height, fps, duration, bg, fg, font_size):
    """Text scrolls horizontally across the frame."""
    frames = []
    total_frames = int(fps * duration)
    font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", font_size)
    bbox = font.getbbox(text)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    y = (height - text_h) // 2

    for i in range(total_frames):
        img = Image.new("RGBA", (width, height), bg)
        draw = ImageDraw.Draw(img)
        t = i / max(total_frames - 1, 1)
        # Start off-screen right, scroll to off-screen left
        x = int(width - t * (width + text_w))
        draw.text((x, y), text, fill=fg, font=font)
        frames.append(img)

    return frames


EFFECTS = {
    "typewriter": typewriter,
    "bounce": bounce,
    "scroll": scroll,
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--text", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--effect", default="typewriter", choices=EFFECTS.keys())
    parser.add_argument("--width", type=int, default=400)
    parser.add_argument("--height", type=int, default=200)
    parser.add_argument("--fps", type=int, default=10)
    parser.add_argument("--duration", type=float, default=2.0)
    parser.add_argument("--bg", default="black")
    parser.add_argument("--fg", default="white")
    parser.add_argument("--font-size", type=int, default=40)
    args = parser.parse_args()

    effect_fn = EFFECTS[args.effect]
    frames = effect_fn(
        args.text,
        args.width,
        args.height,
        args.fps,
        args.duration,
        args.bg,
        args.fg,
        args.font_size,
    )

    # Convert RGBA to P mode with transparency for GIF
    gif_frames = []
    for frame in frames:
        converted = frame.convert("RGB")
        gif_frames.append(converted)

    frame_duration = int(1000 / args.fps)
    gif_frames[0].save(
        args.output,
        save_all=True,
        append_images=gif_frames[1:],
        duration=frame_duration,
        loop=0,
    )


if __name__ == "__main__":
    main()
