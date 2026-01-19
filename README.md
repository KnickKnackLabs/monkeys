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

## Usage

```bash
monkeys          # Show available commands
monkeys welcome  # Verify setup
```

## Development

This project uses [shimmer](https://github.com/ricon-family/shimmer) for agent workflows.
