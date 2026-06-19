#!/usr/bin/env bats

load test_helper

setup() {
  export MONKEYS_CALLER_PWD="$BATS_TEST_TMPDIR/caller"
  mkdir -p "$MONKEYS_CALLER_PWD"

  mock_bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$mock_bin"

  export FFMPEG="$mock_bin/ffmpeg"
  export QWEN_ASR_DIR="$BATS_TEST_TMPDIR/qwen-asr"
  export MONKEYS_TEST_FFMPEG_LOG="$BATS_TEST_TMPDIR/ffmpeg.log"
  export MONKEYS_TEST_QWEN_LOG="$BATS_TEST_TMPDIR/qwen.log"
  : > "$MONKEYS_TEST_FFMPEG_LOG"
  : > "$MONKEYS_TEST_QWEN_LOG"

  mkdir -p "$QWEN_ASR_DIR/qwen3-asr-0.6b"

  cat > "$FFMPEG" <<'MOCK_FFMPEG'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MONKEYS_TEST_FFMPEG_LOG"

input=""
args=("$@")
for ((i = 0; i < $#; i++)); do
  if [ "${args[$i]}" = "-i" ]; then
    input="${args[$((i + 1))]}"
  fi
done

out="${args[$(( $# - 1 ))]}"
if [ -n "${MONKEYS_TEST_FFMPEG_EXIT_BEFORE_WRITE:-}" ]; then
  exit "$MONKEYS_TEST_FFMPEG_EXIT_BEFORE_WRITE"
fi

if [ "$out" = "-" ]; then
  printf 'raw audio from %s\n' "$input"
else
  mkdir -p "$(dirname "$out")"
  printf 'wav audio from %s\n' "$input" > "$out"
fi
if [ -n "${MONKEYS_TEST_FFMPEG_EXIT_AFTER_WRITE:-}" ]; then
  exit "$MONKEYS_TEST_FFMPEG_EXIT_AFTER_WRITE"
fi
MOCK_FFMPEG

  cat > "$QWEN_ASR_DIR/qwen_asr" <<'MOCK_QWEN'
#!/usr/bin/env bash
set -euo pipefail
stream=false
prompt=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --stream)
      stream=true
      shift
      ;;
    --prompt)
      prompt="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
stdin_text="$(cat)"
printf 'stream=%s\nprompt=%s\nstdin=%s\n---\n' "$stream" "$prompt" "$stdin_text" >> "$MONKEYS_TEST_QWEN_LOG"
if [ "$stream" = "true" ]; then
  printf 'live chunk one '
  printf 'live chunk two'
else
  printf 'final transcript'
fi
MOCK_QWEN

  chmod +x "$FFMPEG" "$QWEN_ASR_DIR/qwen_asr"
}

@test "listen records WAV output to caller-relative path" {
  run monkeys listen --device ':unit' --duration 1 -o recording.wav
  [ "$status" -eq 0 ]
  [ -s "$MONKEYS_CALLER_PWD/recording.wav" ]
  grep -q -- '-i :unit' "$MONKEYS_TEST_FFMPEG_LOG"
  grep -q -- '-f wav' "$MONKEYS_TEST_FFMPEG_LOG"
  [[ "$(cat "$BATS_TEST_TMPDIR/stderr")" == *"Saved to $MONKEYS_CALLER_PWD/recording.wav"* ]]
}

@test "listen keeps interrupted WAV recordings that were written" {
  export MONKEYS_TEST_FFMPEG_EXIT_AFTER_WRITE=130
  run monkeys listen --device ':unit' -o interrupted.wav
  unset MONKEYS_TEST_FFMPEG_EXIT_AFTER_WRITE
  [ "$status" -eq 0 ]
  [ -s "$MONKEYS_CALLER_PWD/interrupted.wav" ]
  [[ "$(cat "$BATS_TEST_TMPDIR/stderr")" == *"Recording command exited with status 130 after writing audio"* ]]
  [[ "$(cat "$BATS_TEST_TMPDIR/stderr")" == *"Saved to $MONKEYS_CALLER_PWD/interrupted.wav"* ]]
}

@test "listen does not let stale output mask failed recording" {
  printf 'old audio\n' > "$MONKEYS_CALLER_PWD/stale.wav"
  export MONKEYS_TEST_FFMPEG_EXIT_BEFORE_WRITE=1
  run monkeys listen --device ':unit' -o stale.wav
  unset MONKEYS_TEST_FFMPEG_EXIT_BEFORE_WRITE
  [ "$status" -ne 0 ]
  [ "$(cat "$MONKEYS_CALLER_PWD/stale.wav")" = "old audio" ]
  [[ "$(cat "$BATS_TEST_TMPDIR/stderr")" == *"recording failed or produced an empty file"* ]]
}

@test "listen writes raw audio to piped stdout when output is omitted" {
  run monkeys listen --device ':unit' --duration 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"raw audio from :unit"* ]]
}

@test "listen rejects raw stdout and file output together" {
  run monkeys listen --raw -o recording.wav
  [ "$status" -ne 0 ]
  [[ "$(cat "$BATS_TEST_TMPDIR/stderr")" == *"choose either --raw/stdout or --output"* ]]
}

@test "hear file input defaults to batch transcription" {
  printf 'wav fixture\n' > "$MONKEYS_CALLER_PWD/input.wav"

  run monkeys hear input.wav --prompt "Preserve spelling: CMMC" --no-cache
  [ "$status" -eq 0 ]
  [ "$output" = "final transcript" ]
  grep -q 'stream=false' "$MONKEYS_TEST_QWEN_LOG"
  grep -q 'prompt=Preserve spelling: CMMC' "$MONKEYS_TEST_QWEN_LOG"
}

@test "hear stdin defaults to streaming transcription" {
  run bash -c 'cd "$REPO_DIR" && printf raw-audio | mise run -q hear 2>"$BATS_TEST_TMPDIR/stderr"'
  [ "$status" -eq 0 ]
  [ "$output" = "live chunk one live chunk two" ]
  grep -q 'stream=true' "$MONKEYS_TEST_QWEN_LOG"
  grep -q 'stdin=raw-audio' "$MONKEYS_TEST_QWEN_LOG"
}

@test "hear --batch disables stdin streaming" {
  run bash -c 'cd "$REPO_DIR" && printf raw-audio | mise run -q hear --batch - 2>"$BATS_TEST_TMPDIR/stderr"'
  [ "$status" -eq 0 ]
  [ "$output" = "final transcript" ]
  grep -q 'stream=false' "$MONKEYS_TEST_QWEN_LOG"
}

@test "hear reads caller-relative prompt files" {
  printf 'In Tolerance\nProShop\nCMMC\n' > "$MONKEYS_CALLER_PWD/glossary.txt"
  printf 'wav fixture\n' > "$MONKEYS_CALLER_PWD/input.wav"

  run monkeys hear input.wav --prompt-file glossary.txt --no-cache
  [ "$status" -eq 0 ]
  grep -q 'In Tolerance' "$MONKEYS_TEST_QWEN_LOG"
  grep -q 'ProShop' "$MONKEYS_TEST_QWEN_LOG"
  grep -q 'CMMC' "$MONKEYS_TEST_QWEN_LOG"
}

@test "hear rejects conflicting stream and batch flags" {
  run bash -c 'cd "$REPO_DIR" && printf raw-audio | mise run -q hear --stream --batch - 2>"$BATS_TEST_TMPDIR/stderr"'
  [ "$status" -ne 0 ]
  [[ "$(cat "$BATS_TEST_TMPDIR/stderr")" == *"choose either --stream or --batch"* ]]
}

@test "listen to hear pipeline streams text" {
  run bash -c 'cd "$REPO_DIR" && mise run -q listen --device ":unit" --duration 1 2>"$BATS_TEST_TMPDIR/listen.stderr" | mise run -q hear 2>"$BATS_TEST_TMPDIR/hear.stderr"'
  [ "$status" -eq 0 ]
  [ "$output" = "live chunk one live chunk two" ]
  grep -q 'stream=true' "$MONKEYS_TEST_QWEN_LOG"
  grep -q 'raw audio from :unit' "$MONKEYS_TEST_QWEN_LOG"
}
