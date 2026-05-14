#!/bin/bash
# Usage: plugins_install_codex.sh <command> [args...]
# Runs <command> for each codex_* account.
set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <command> [args...]" >&2
    exit 1
fi

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

for src in "$SCRIPTS_DIR/codex_"*.sh; do
    [ -f "$src" ] || continue
    eval "$(grep '^HOME=' "$src")" 2>/dev/null || continue
    [ -d "$HOME" ] || continue
    export HOME
    [ -f "$SCRIPTS_DIR/proxy.env" ] && source "$SCRIPTS_DIR/proxy.env"
    echo "==> $(basename "$HOME")"
    eval "$@"
done
