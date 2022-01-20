#!/bin/bash
set -eu -o pipefail

if [[ $(command -v docker) ]]; then
  docker container run \
    --name rubocop$$ \
    --rm \
    -t \
    -u "$(id -u):$(id -g)" \
    -v "$PWD":/work:ro \
    docker.io/shakiyam/rubocop "$@"
else
  podman container run \
    --name rubocop$$ \
    --rm \
    --security-opt label=disable \
    -t \
    -v "$PWD":/work:ro \
    docker.io/shakiyam/rubocop "$@"
fi
