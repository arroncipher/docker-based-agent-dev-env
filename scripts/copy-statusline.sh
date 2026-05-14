#!/bin/bash
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $(basename "$0") <src_dir> <dst_dir>" >&2
  exit 1
fi

src="$1"
dst="$2"
script_file="statusline-command.sh"
settings_file="settings.json"

if [ ! -f "${src}/${script_file}" ]; then
  echo "Error: ${src}/${script_file} not found" >&2
  exit 1
fi

if [ ! -d "$dst" ]; then
  echo "Error: destination directory ${dst} does not exist" >&2
  exit 1
fi

# copy the statusline script
cp "${src}/${script_file}" "${dst}/${script_file}"
echo "Copied ${src}/${script_file} -> ${dst}/${script_file}"

# wire up statusLine in settings.json
dst_settings="${dst}/${settings_file}"
if [ ! -f "$dst_settings" ]; then
  echo "Error: ${dst_settings} not found" >&2
  exit 1
fi

tmp=$(mktemp)
jq '. + {"statusLine": {"type": "command", "command": "sh ~/.claude/statusline-command.sh"}}' \
  "$dst_settings" > "$tmp" && mv "$tmp" "$dst_settings"
echo "Updated ${dst_settings}: statusLine.command = sh ~/.claude/statusline-command.sh"
