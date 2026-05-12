#!/bin/bash
HOME="$(cd "$(dirname "$0")/../.coding_agents/claude_max20" && pwd)"
[ -d "$HOME" ] || mkdir -p "$HOME"
[ -f "$(dirname "$0")/proxy.env" ] && source "$(dirname "$0")/proxy.env"
exec claude "$@"
