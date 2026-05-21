#!/bin/bash
HOME="$(cd "$(dirname "$0")/../.coding_agents/codex_plus" && pwd)"
[ -d "$HOME" ] || mkdir -p "$HOME"
[ -f "$(dirname "$0")/proxy.env" ] && source "$(dirname "$0")/proxy.env"
exec codex --dangerously-bypass-approvals-and-sandbox "$@"
