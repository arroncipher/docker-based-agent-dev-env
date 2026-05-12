#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/host-env.sh"

IMAGE_CONTEXT="${1:-$CODING_AGENT_IMAGE_CONTEXT}"

if [ ! -f "$IMAGE_CONTEXT/Dockerfile" ]; then
  echo "Dockerfile not found under image context: $IMAGE_CONTEXT" >&2
  exit 1
fi

docker build -t "$CODING_AGENT_IMAGE_BASE" "$IMAGE_CONTEXT"
