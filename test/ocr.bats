#!/usr/bin/env bats

load test_helper

FIXTURE="$MISE_CONFIG_ROOT/test/fixtures/test-ocr.png"

# All tests use the real EasyOCR (integration tests).
# First run downloads models (~50MB); subsequent runs use cache.

@test "ocr: outputs JSON with text and coordinates" {
  run monkeys ocr "$FIXTURE"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'type == "array"'
  echo "$output" | jq -e 'length > 0'
}

@test "ocr: each entry has required fields" {
  run monkeys ocr "$FIXTURE"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.[0] | has("text", "x", "y", "w", "h", "cx", "cy", "confidence")'
}

@test "ocr: detects Hello World" {
  run monkeys ocr "$FIXTURE"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'map(select(.text | test("Hello"; "i"))) | length > 0'
}

@test "ocr: detects Select and Cancel" {
  run monkeys ocr "$FIXTURE"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'map(select(.text | test("Select"; "i"))) | length > 0'
  echo "$output" | jq -e 'map(select(.text | test("Cancel"; "i"))) | length > 0'
}

@test "ocr: --find filters by substring" {
  run monkeys ocr "$FIXTURE" --find "select"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'length == 1'
  echo "$output" | jq -e '.[0].text | test("Select"; "i")'
}

@test "ocr: --find is case-insensitive" {
  run monkeys ocr "$FIXTURE" --find "SELECT"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'length == 1'
}

@test "ocr: --find with no match returns empty array" {
  run monkeys ocr "$FIXTURE" --find "nonexistent"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'length == 0'
}

@test "ocr: --text-only outputs plain text" {
  run monkeys ocr "$FIXTURE" --text-only
  [ "$status" -eq 0 ]
  [[ "$output" == *"Hello"* ]]
  # Should not start with [ (not JSON)
  [[ "$output" != \[* ]]
}

@test "ocr: --text-only with --find filters" {
  run monkeys ocr "$FIXTURE" --text-only --find "cancel"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cancel"* ]]
  [[ "$output" != *"Hello"* ]]
}

@test "ocr: cx/cy are center of bounding box" {
  run monkeys ocr "$FIXTURE"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '
    [.[] | .cx == (.x + (.w / 2 | floor)) and .cy == (.y + (.h / 2 | floor))] | all
  '
}

@test "ocr: fails on missing file" {
  run monkeys ocr "/nonexistent/image.png"
  [ "$status" -ne 0 ]
  [[ "$(cat "$BATS_TEST_TMPDIR/stderr")" == *"Error: file not found"* ]]
}

@test "ocr: confidence values are between 0 and 1" {
  run monkeys ocr "$FIXTURE"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '[.[] | .confidence >= 0 and .confidence <= 1] | all'
}
