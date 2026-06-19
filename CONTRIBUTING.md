# Contributing

`monkeys` is a mise/shiv tool for command-line media: image generation, speech synthesis, microphone capture, speech-to-text, and OCR.

## Structure

```text
monkeys/
├── mise.toml              # tools, settings, and codebase lint config
├── README.tsx             # source for generated README.md
├── README.md              # generated; keep in sync with README.tsx
├── CONTRIBUTING.md        # repo orientation surface
├── .mise/tasks/           # public command surface exposed by shiv
├── scripts/               # Python helpers for heavier media backends
└── test/                  # BATS tests and helpers
```

## Local setup

```bash
mise trust
mise install
mise run test
mise run doctor
```

`doctor` reports whether the optional local `codebase pre-commit` hook is installed.
Install it in your clone when you want convention lints to run before every commit:

```bash
codebase pre-commit
```

The hook lives under `.git/hooks/`, so it is intentionally not tracked by the repo.

## Task style

- Keep public behavior in `.mise/tasks/*`; shiv exposes them as `monkeys ...` commands.
- Use `$MISE_CONFIG_ROOT` inside tasks when a task needs the repo root; outside tasks, self-locate or use the test helper's `$REPO_DIR`.
- Use `${TOOL:-tool}` for external commands so tests can inject mocks.
- For caller-relative paths, read `MONKEYS_CALLER_PWD`, not generic `CALLER_PWD`.
- Keep binary/audio/image artifacts out of Git unless they are explicit test fixtures.

## README workflow

Edit `README.tsx`, then regenerate and check the output:

```bash
readme build
readme build --check
```

CI also checks that `README.md` matches `README.tsx`.

## Validation before merge

```bash
mise run test
codebase lint "$PWD"
readme build --check
git diff --check
```
