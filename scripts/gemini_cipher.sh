#!/bin/bash
HOME="$(cd "$(dirname "$0")/../.coding_agents/gemini_cipher" && pwd)"
[ -d "$HOME" ] || mkdir -p "$HOME"
[ -f "$(dirname "$0")/proxy.env" ] && source "$(dirname "$0")/proxy.env"
exec gemini "$@"
