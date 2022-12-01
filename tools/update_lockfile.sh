#!/bin/bash
set -eu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
# shellcheck disable=SC1091
. "$SCRIPT_DIR"/colored_echo.sh

[[ -e Gemfile.lock ]] || touch Gemfile.lock
if [[ $(command -v docker) ]]; then
  docker container run \
    --name update_lockfile$$ \
    --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PWD/Gemfile":/work/Gemfile:ro \
    -v "$PWD/Gemfile.lock":/work/Gemfile.lock \
    -w /work \
    docker.io/ruby:3.1-alpine3.17 sh -c 'HOME=/tmp bundle lock --update'
elif [[ $(command -v podman) ]]; then
  podman container run \
    --name update_lockfile$$ \
    --rm \
    --security-opt label=disable \
    -v "$PWD/Gemfile":/work/Gemfile:ro \
    -v "$PWD/Gemfile.lock":/work/Gemfile.lock \
    -w /work \
    docker.io/ruby:3.1-alpine3.17 sh -c 'HOME=/tmp bundle lock --update'
else
  echo_error 'Neither docker nor podman is installed.'
  exit 1
fi
