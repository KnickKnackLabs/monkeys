# /// script
# dependencies = ["kokoro-onnx", "soundfile"]
# ///

import argparse
import soundfile as sf
from kokoro_onnx import Kokoro


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--text", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--voice", default="af_heart")
    parser.add_argument("--speed", type=float, default=1.0)
    parser.add_argument("--model-dir", required=True)
    args = parser.parse_args()

    model_path = f"{args.model_dir}/kokoro-v1.0.onnx"
    voices_path = f"{args.model_dir}/voices-v1.0.bin"

    kokoro = Kokoro(model_path, voices_path)
    samples, sample_rate = kokoro.create(
        args.text,
        voice=args.voice,
        speed=args.speed,
        lang="en-us",
    )

    sf.write(args.output, samples, sample_rate)


if __name__ == "__main__":
    main()
