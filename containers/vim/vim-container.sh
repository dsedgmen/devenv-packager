#!/bin/bash
# Vim Container Wrapper
# Makes containerized vim feel like native vim

# Pass through API keys if set
ENV_ARGS=""
if [ -n "$ANTHROPIC_API_KEY" ]; then
    ENV_ARGS="$ENV_ARGS -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
fi
if [ -n "$GEMINI_API_KEY" ]; then
    ENV_ARGS="$ENV_ARGS -e GEMINI_API_KEY=$GEMINI_API_KEY"
fi
if [ -n "$DEVENV_AI_BACKEND" ]; then
    ENV_ARGS="$ENV_ARGS -e DEVENV_AI_BACKEND=$DEVENV_AI_BACKEND"
fi

# Run vim in container
exec podman run --rm -it \
    --userns=keep-id \
    --security-opt label=disable \
    -v "$(pwd):/workspace:z" \
    -v "$HOME/.gitconfig:/home/$(whoami)/.gitconfig:ro" \
    --network=host \
    $ENV_ARGS \
    "${DEVENV_VIM_IMAGE:-vim:latest}" \
    "$@"
