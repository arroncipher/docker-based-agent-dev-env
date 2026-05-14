#!/bin/bash
# Usage: plugins_install_claude.sh <command> [args...]
# Runs <command> for each claude_* account.
# Example: plugins_install_claude.sh 'npx ccusage@latest'
set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <command> [args...]" >&2
    exit 1
fi

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

for src in "$SCRIPTS_DIR/claude_"*.sh; do
    [ -f "$src" ] || continue
    eval "$(grep '^HOME=' "$src")" 2>/dev/null || continue
    [ -d "$HOME" ] || continue
    export HOME
    [ -f "$SCRIPTS_DIR/proxy.env" ] && source "$SCRIPTS_DIR/proxy.env"
    echo "==> $(basename "$HOME")"
    eval "$@"
done
