#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

write_passing_test() {
  local path="$1" name="$2"
  local test_keyword='@test'
  mkdir -p "$(dirname "$path")"
  printf '%s\n' \
    '#!/usr/bin/env bats' \
    "$test_keyword \"$name\" {" \
    '  true' \
    '}' > "$path"
}

@test "options-only calls use the configured default test directory" {
  run monkeys test --jobs 1 --filter '^listen rejects raw stdout and file output together$'

  [ "$status" -eq 0 ]
  [[ "$output" == *'1..1'* ]]
  [[ "$output" == *'ok 1 listen rejects raw stdout and file output together'* ]]
}

@test "an explicit test target takes precedence over the configured default" {
  local target="$BATS_TEST_TMPDIR/explicit.bats"
  write_passing_test "$target" 'explicit target only'

  run monkeys test --jobs 1 "$target"

  [ "$status" -eq 0 ]
  [[ "$output" == *'1..1'* ]]
  [[ "$output" == *'ok 1 explicit target only'* ]]
}

@test "relative test targets resolve from the repository root" {
  run monkeys test --jobs 1 test/listen_hear.bats --filter '^listen rejects raw stdout and file output together$'

  [ "$status" -eq 0 ]
  [[ "$output" == *'1..1'* ]]
  [[ "$output" == *'ok 1 listen rejects raw stdout and file output together'* ]]
}

@test "whitespace-bearing explicit test targets remain one argument" {
  local target="$BATS_TEST_TMPDIR/explicit target/passing test.bats"
  write_passing_test "$target" 'whitespace target'

  run monkeys test --jobs 2 "$target"

  [ "$status" -eq 0 ]
  [[ "$output" == *'1..1'* ]]
  [[ "$output" == *'ok 1 whitespace target'* ]]
}

@test "the public test path stays serial by default" {
  local target="$BATS_TEST_TMPDIR/default-jobs.bats"
  local test_keyword='@test'
  cat > "$target" <<BATS
#!/usr/bin/env bats

$test_keyword "default job count" {
  [ "\$BATS_NUMBER_OF_PARALLEL_JOBS" = 1 ]
}
BATS

  run monkeys test "$target"

  [ "$status" -eq 0 ]
  [[ "$output" == *'ok 1 default job count'* ]]
}

@test "callers can explicitly run separate BATS files concurrently through Rush" {
  local probe_dir="$BATS_TEST_TMPDIR/across-file-probe"
  local barrier_dir="$BATS_TEST_TMPDIR/across-file-barrier"
  mkdir -p "$probe_dir" "$barrier_dir"

  test_keyword='@test'
  {
    printf '%s\n' '#!/usr/bin/env bats'
    printf '%s\n' "$test_keyword \"first worker observes second worker\" {"
    cat <<'INNER_BATS'
  touch "$PROBE_DIR/one"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/two" ] || return 0
    sleep 0.05
  done
  false
}
INNER_BATS
  } > "$probe_dir/one.bats"

  {
    printf '%s\n' '#!/usr/bin/env bats'
    printf '%s\n' "$test_keyword \"second worker observes first worker\" {"
    cat <<'INNER_BATS'
  touch "$PROBE_DIR/two"
  for _ in {1..50}; do
    [ ! -e "$PROBE_DIR/one" ] || return 0
    sleep 0.05
  done
  false
}
INNER_BATS
  } > "$probe_dir/two.bats"

  export PROBE_DIR="$barrier_dir"
  run monkeys test --jobs 2 "$probe_dir"

  [ "$status" -eq 0 ]
}
