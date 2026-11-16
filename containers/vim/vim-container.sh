#!/usr/bin/env bash
# Run packager vim image with workspace mounted.
set -euo pipefail

env_args=()
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  env_args+=(-e "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}")
fi
if [[ -n "${GEMINI_API_KEY:-}" ]]; then
  env_args+=(-e "GEMINI_API_KEY=${GEMINI_API_KEY}")
fi
if [[ -n "${DEVENV_AI_BACKEND:-}" ]]; then
  env_args+=(-e "DEVENV_AI_BACKEND=${DEVENV_AI_BACKEND}")
fi

exec podman run --rm -it \
  --userns=keep-id \
  --security-opt label=disable \
  -v "$(pwd):/workspace:z" \
  -v "${HOME}/.gitconfig:/home/$(whoami)/.gitconfig:ro" \
  --network=host \
  "${env_args[@]}" \
  "${DEVENV_VIM_IMAGE:-vim:latest}" \
  "$@"
