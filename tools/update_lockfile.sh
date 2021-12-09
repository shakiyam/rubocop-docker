#!/bin/bash
set -eu -o pipefail

[[ -e Gemfile.lock ]] || touch Gemfile.lock
if [[ $(command -v podman) ]]; then
  podman container run \
    --name update_lockfile$$ \
    --rm \
    --security-opt label=disable \
    -v "$PWD/Gemfile":/work/Gemfile:ro \
    -v "$PWD/Gemfile.lock":/work/Gemfile.lock \
    -w /work \
    docker.io/ruby:alpine sh -c 'HOME=/tmp bundle lock --update'
else
  docker container run \
    --name update_lockfile$$ \
    --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PWD/Gemfile":/work/Gemfile:ro \
    -v "$PWD/Gemfile.lock":/work/Gemfile.lock \
    -w /work \
    ruby:alpine sh -c 'HOME=/tmp bundle lock --update'
fi
