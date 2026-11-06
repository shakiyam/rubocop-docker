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

# TODO: Remove once base image includes json >= 2.19.9 (CVE-2026-33210, CVE-2026-54696)
# shellcheck disable=SC2016
if ! JSON_LOADED=$($CONTAINER_ENGINE container run \
  --name "test_rubocop_$(uuidgen | head -c8)" \
  --rm \
  --pull=never \
  "${ENGINE_OPTS[@]}" \
  --entrypoint ruby \
  "$IMAGE_NAME" -e '
    require "json"
    path = $LOADED_FEATURES.grep(%r{/json/version\.rb\z}).first.to_s
    puts "#{JSON::VERSION} from #{path}"
    exit(Gem::Version.new(JSON::VERSION) >= Gem::Version.new("2.19.9") && path.start_with?("/usr/local/bundle/"))
  '); then
  echo_error "Test failed: json ${JSON_LOADED} is loaded instead of >= 2.19.9 from /usr/local/bundle."
  exit 1
fi
# shellcheck disable=SC2016
if ! DEFAULT_JSON=$($CONTAINER_ENGINE container run \
  --name "test_rubocop_$(uuidgen | head -c8)" \
  --rm \
  --pull=never \
  "${ENGINE_OPTS[@]}" \
  --entrypoint ruby \
  "$IMAGE_NAME" -e '
    specs = Dir.glob(File.join(Gem.default_specifications_dir, "json-*.gemspec"))
    puts specs.join(" ")
    exit(specs.empty?)
  '); then
  echo_error "Test failed: the default json gem remains in ${DEFAULT_JSON}."
  exit 1
fi

echo_success 'Test passed: rubocop detected the offense and accepted the clean file.'
