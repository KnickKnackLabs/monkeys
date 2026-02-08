# /// script
# dependencies = ["pywhispercpp"]
# ///

import argparse
from pywhispercpp.model import Model


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--model", default="base.en")
    parser.add_argument("--models-dir")
    args = parser.parse_args()

    kwargs = {}
    if args.models_dir:
        kwargs["models_dir"] = args.models_dir

    model = Model(args.model, **kwargs)
    segments = model.transcribe(args.input)

    for segment in segments:
        print(segment.text)


if __name__ == "__main__":
    main()
