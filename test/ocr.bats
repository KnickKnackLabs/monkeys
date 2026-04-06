#!/usr/bin/env bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
FIXTURE="$SCRIPT_DIR/test/fixtures/test-ocr.png"

# All tests use the real EasyOCR (integration tests).
# First run downloads models (~50MB); subsequent runs use cache.

# Helper: run ocr.py, capturing only stdout (stderr has torch warnings)
ocr() {
  uv run "$SCRIPT_DIR/scripts/ocr.py" "$@" 2>/dev/null
}

@test "ocr: outputs JSON with text and coordinates" {
  local result
  result=$(ocr "$FIXTURE")
  echo "$result" | jq -e 'type == "array"'
  local count
  count=$(echo "$result" | jq 'length')
  [ "$count" -gt 0 ]
}

@test "ocr: each entry has required fields" {
  local result
  result=$(ocr "$FIXTURE")
  echo "$result" | jq -e '.[0] | has("text", "x", "y", "w", "h", "cx", "cy", "confidence")'
}

@test "ocr: detects Hello World" {
  local result
  result=$(ocr "$FIXTURE")
  echo "$result" | jq -e 'map(select(.text | test("Hello"; "i"))) | length > 0'
}

@test "ocr: detects Select and Cancel" {
  local result
  result=$(ocr "$FIXTURE")
  echo "$result" | jq -e 'map(select(.text | test("Select"; "i"))) | length > 0'
  echo "$result" | jq -e 'map(select(.text | test("Cancel"; "i"))) | length > 0'
}

@test "ocr: --find filters by substring" {
  local result
  result=$(ocr "$FIXTURE" --find "select")
  local count
  count=$(echo "$result" | jq 'length')
  [ "$count" -eq 1 ]
  echo "$result" | jq -e '.[0].text | test("Select"; "i")'
}

@test "ocr: --find is case-insensitive" {
  local result
  result=$(ocr "$FIXTURE" --find "SELECT")
  local count
  count=$(echo "$result" | jq 'length')
  [ "$count" -eq 1 ]
}

@test "ocr: --find with no match returns empty array" {
  local result
  result=$(ocr "$FIXTURE" --find "nonexistent")
  echo "$result" | jq -e 'length == 0'
}

@test "ocr: --text-only outputs plain text" {
  local result
  result=$(ocr "$FIXTURE" --text-only)
  [[ "$result" == *"Hello"* ]]
  # Should not start with [ (not JSON)
  [[ "$result" != \[* ]]
}

@test "ocr: --text-only with --find filters" {
  local result
  result=$(ocr "$FIXTURE" --text-only --find "cancel")
  [[ "$result" == *"Cancel"* ]]
  [[ "$result" != *"Hello"* ]]
}

@test "ocr: cx/cy are center of bounding box" {
  local result
  result=$(ocr "$FIXTURE")
  echo "$result" | jq -e '
    [.[] | .cx == (.x + (.w / 2 | floor)) and .cy == (.y + (.h / 2 | floor))] | all
  '
}

@test "ocr: fails on missing file" {
  run uv run "$SCRIPT_DIR/scripts/ocr.py" "/nonexistent/image.png" 2>/dev/null
  [ "$status" -ne 0 ]
}

@test "ocr: confidence values are between 0 and 1" {
  local result
  result=$(ocr "$FIXTURE")
  echo "$result" | jq -e '[.[] | .confidence >= 0 and .confidence <= 1] | all'
}
