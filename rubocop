#!/bin/bash
set -eu -o pipefail

if [[ $(command -v podman) ]]; then
  podman container run \
    --name rubocop$$ \
    --rm \
    -t \
    --security-opt label=disable \
    -v "$PWD":/work:ro \
    shakiyam/rubocop "$@"
else
  docker container run \
    --name rubocop$$ \
    --rm \
    -t \
    -u "$(id -u):$(id -g)" \
    -v "$PWD":/work:ro \
    shakiyam/rubocop "$@"
fi
