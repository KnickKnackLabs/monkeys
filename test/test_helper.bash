#!/usr/bin/env bash
# Shared fixtures for monkeys tests.

# Run a repo task through mise so tests exercise the real task path.
# Stderr is redirected to $BATS_TEST_TMPDIR/stderr so tests can check
# error messages without torch/EasyOCR warnings polluting $output.
monkeys() {
  if [ -z "${MONKEYS_CALLER_PWD:-}" ]; then
    echo "MONKEYS_CALLER_PWD not set" >&2
    return 1
  fi
  cd "$REPO_DIR" && MONKEYS_CALLER_PWD="$MONKEYS_CALLER_PWD" mise run -q "$@" 2>"$BATS_TEST_TMPDIR/stderr"
}
export -f monkeys

setup() {
  export MONKEYS_CALLER_PWD="$BATS_TEST_TMPDIR"
}
