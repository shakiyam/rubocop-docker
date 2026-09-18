#!/bin/bash
set -Eeu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
# shellcheck disable=SC1091
. "$SCRIPT_DIR"/tools/colored_echo.sh
# shellcheck disable=SC1091
. "$SCRIPT_DIR"/tools/container_engine.sh

CONTAINER_ENGINE=$(detect_container_engine)
readonly CONTAINER_ENGINE

IMAGE_NAME=ghcr.io/shakiyam/rubocop
readonly IMAGE_NAME

if [[ $CONTAINER_ENGINE == docker ]]; then
  ENGINE_OPTS=(-u "$(id -u):$(id -g)")
else
  ENGINE_OPTS=(--security-opt label=disable)
fi
readonly ENGINE_OPTS

WORK_DIR=$(mktemp -d)
readonly WORK_DIR
trap 'rm -rf "$WORK_DIR"' EXIT

cat >"$WORK_DIR"/.rubocop.yml <<'EOF'
AllCops:
  NewCops: enable
  SuggestExtensions: false
Style/FrozenStringLiteralComment:
  Enabled: false
EOF
# Style/StringLiterals: double quotes without interpolation
echo 'puts "hello"' >"$WORK_DIR"/offense.rb
echo "puts 'hello'" >"$WORK_DIR"/clean.rb

run_rubocop() {
  $CONTAINER_ENGINE container run \
    --name "test_rubocop_$(uuidgen | head -c8)" \
    --rm \
    --pull=never \
    "${ENGINE_OPTS[@]}" \
    -v "$WORK_DIR":/work:ro \
    -w /work \
    "$IMAGE_NAME" "$@"
}

if OUTPUT=$(run_rubocop offense.rb 2>&1); then
  echo_error 'Test failed: rubocop did not detect the offense in offense.rb.'
  echo "$OUTPUT"
  exit 1
else
  STATUS=$?
fi
if [[ $STATUS -ne 1 ]]; then
  echo_error "Test failed: rubocop exited with an unexpected status $STATUS."
  echo "$OUTPUT"
  exit 1
fi
if ! grep -q 'Style/StringLiterals' <<<"$OUTPUT"; then
  echo_error 'Test failed: rubocop output does not mention Style/StringLiterals.'
  echo "$OUTPUT"
  exit 1
fi

if ! OUTPUT=$(run_rubocop clean.rb 2>&1); then
  echo_error 'Test failed: rubocop reported offenses in clean.rb.'
  echo "$OUTPUT"
  exit 1
fi

echo_success 'Test passed: rubocop detected the offense and accepted the clean file.'
