# Tests must be run via `mise run test` (or `monkeys test`)
if [ -z "${MISE_CONFIG_ROOT:-}" ]; then
  echo "MISE_CONFIG_ROOT not set — run tests via: mise run test" >&2
  exit 1
fi

# monkeys() wrapper — calls tasks via mise, just like real usage.
# Stderr is redirected to $BATS_TEST_TMPDIR/stderr so tests can check
# error messages without torch/EasyOCR warnings polluting $output.
monkeys() {
  if [ -z "${CALLER_PWD:-}" ]; then
    echo "CALLER_PWD not set" >&2
    return 1
  fi
  cd "$MISE_CONFIG_ROOT" && CALLER_PWD="$CALLER_PWD" mise run -q "$@" 2>"$BATS_TEST_TMPDIR/stderr"
}
export -f monkeys

setup() {
  export CALLER_PWD="$BATS_TEST_TMPDIR"
}
