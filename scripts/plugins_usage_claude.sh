#!/bin/bash
# Usage: plugins_usage_claude.sh <command>
#   command : shell command string to exec, e.g. 'npx ccusage@latest'
#
# For each scripts/claude_*.sh, produces scripts/claude_<suffix>_<name>.sh
# where <name> is derived from <command> and the exec line is replaced.
#
# Examples:
#   plugins_usage_claude.sh 'npx ccusage@latest'
#     -> claude_max20_ccusage.sh  claude_pro_ccusage.sh  claude_minimax_ccusage.sh  claude_deepseek_ccusage.sh
set -euo pipefail

TOOL=claude
CMD="${1:?Usage: $0 <command>}"
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# derive output name: 'npx ccusage@latest' -> 'ccusage'
_raw="${CMD#npx }"
_raw="${_raw%% *}"
NAME="${_raw%%@*}"

# exec line with @version stripped: 'npx ccusage@latest' -> 'npx ccusage'
CMD_EXEC="$(echo "$CMD" | sed 's/@[^@ ][^ ]*//g')"

count=0
for src in "$SCRIPTS_DIR/${TOOL}_"*.sh; do
    [ -f "$src" ] || continue
    eval "$(grep '^HOME=' "$src")" 2>/dev/null || continue
    [ -d "$HOME" ] || continue
    base="$(basename "$src" .sh)"
    suffix="${base#${TOOL}_}"
    out="$SCRIPTS_DIR/${TOOL}_${suffix}_${NAME}.sh"

    awk -v cmd="$CMD_EXEC" '
        /^exec / { print "exec " cmd " \"$@\""; next }
        { print }
    ' "$src" > "$out"
    chmod +x "$out"
    echo "created: $out"
    count=$((count + 1))
done

[ "$count" -gt 0 ] || { echo "no ${TOOL}_*.sh found in $SCRIPTS_DIR" >&2; exit 1; }
