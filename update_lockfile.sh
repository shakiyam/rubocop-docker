#!/bin/bash
set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

[[ -e "$script_dir/Gemfile.lock" ]] || touch "$script_dir/Gemfile.lock"

docker container run \
  --rm \
  -e http_proxy="${http_proxy:-}" \
  -e https_proxy="${https_proxy:-}" \
  -v "$script_dir/Gemfile":/work/Gemfile:ro \
  -v "$script_dir/Gemfile.lock":/work/Gemfile.lock \
  -u "$(id -u):$(id -g)" \
  -w /work \
  ruby:alpine sh -c 'HOME=/tmp bundle lock --update'
