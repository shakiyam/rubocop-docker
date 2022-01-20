#!/bin/bash
set -eu -o pipefail

[[ -e Gemfile.lock ]] || touch Gemfile.lock
if [[ $(command -v docker) ]]; then
  docker container run \
    --name update_lockfile$$ \
    --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PWD/Gemfile":/work/Gemfile:ro \
    -v "$PWD/Gemfile.lock":/work/Gemfile.lock \
    -w /work \
    docker.io/ruby:3.1-alpine3.15 sh -c 'HOME=/tmp bundle lock --update'
else
  podman container run \
    --name update_lockfile$$ \
    --rm \
    --security-opt label=disable \
    -v "$PWD/Gemfile":/work/Gemfile:ro \
    -v "$PWD/Gemfile.lock":/work/Gemfile.lock \
    -w /work \
    docker.io/ruby:3.1-alpine3.15 sh -c 'HOME=/tmp bundle lock --update'
fi
