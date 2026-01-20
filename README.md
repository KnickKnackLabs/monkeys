# monkeys

CLI for generating images via Hugging Face.

## Install

```bash
git clone https://github.com/KnickKnackLabs/monkeys.git ~/monkeys
cd ~/monkeys && mise trust && mise install

# Add to your shell config (~/.zshrc or ~/.bashrc)
eval "$(mise -C ~/monkeys run -q shell)"

# Reload and verify
source ~/.zshrc
monkeys welcome
```

## Configuration

Set `HF_TOKEN` for Hugging Face API authentication:

```bash
export HF_TOKEN="hf_your_token_here"
```

Get a token at https://huggingface.co/settings/tokens

## Usage

```bash
monkeys generate "a cartoon monkey"                    # Generate image
monkeys generate "pixel art sunset" -o sunset.png      # Custom output file
monkeys generate "a cat" --model stabilityai/stable-diffusion-xl-base-1.0

monkeys welcome   # Verify setup
monkeys tasks     # List all commands
```

You can also pass the token directly:

```bash
monkeys generate "a dog" --token hf_your_token_here
```

## Development

This project uses [shimmer](https://github.com/ricon-family/shimmer) for agent workflows.
