#!/bin/bash
set -eu -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
# shellcheck disable=SC1091
. "$SCRIPT_DIR"/colored_echo.sh

exit_flag=false
while getopts ':e' flag; do
  case "${flag}" in
    e)
      exit_flag=true
      ;;
    *)
      echo_error "Unknown option: -$OPTARG"
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

[[ -e Gemfile.lock ]] || touch Gemfile.lock
if command -v docker &>/dev/null; then
  docker container run \
    --name update_lockfile$$ \
    --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PWD/Gemfile":/work/Gemfile:ro \
    -v "$PWD/Gemfile.lock":/work/Gemfile.lock \
    -w /work \
    public.ecr.aws/docker/library/ruby:3.4.3-slim-bookworm sh -c 'HOME=/tmp bundle lock --update --add-platform aarch64-linux x86_64-linux'
elif command -v podman &>/dev/null; then
  podman container run \
    --name update_lockfile$$ \
    --rm \
    --security-opt label=disable \
    -v "$PWD/Gemfile":/work/Gemfile:ro \
    -v "$PWD/Gemfile.lock":/work/Gemfile.lock \
    -w /work \
    public.ecr.aws/docker/library/ruby:3.4.3-slim-bookworm sh -c 'HOME=/tmp bundle lock --update --add-platform aarch64-linux x86_64-linux'
else
  echo_error 'Neither docker nor podman is installed.'
  exit 1
fi

if [[ -n $(git diff Gemfile.lock) ]]; then
  echo_warn 'Gemfile.lock is updated.'
  git --no-pager diff Gemfile.lock
  if $exit_flag; then
    exit 2
  fi
fi
