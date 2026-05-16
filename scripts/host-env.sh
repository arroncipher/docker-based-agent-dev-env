#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ENV_ROOT="${DEV_ENV_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
CODING_AGENT_IMAGE_BASE="${CODING_AGENT_IMAGE_BASE:-coding-agent-base:debian-bookworm}"
CODING_AGENT_IMAGE_CONTEXT="${CODING_AGENT_IMAGE_CONTEXT:-$DEV_ENV_ROOT/coding_agent_env/images/coding-agent-base/debian-bookworm}"

export DEV_ENV_ROOT
export CODING_AGENT_IMAGE_BASE
export CODING_AGENT_IMAGE_CONTEXT
export PATH="$PATH:$SCRIPT_DIR"
