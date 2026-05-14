#!/bin/bash
# Update .bashrc and .zshrc with scripts PATH

BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"
SCRIPTS_PATH="$(cd "$(dirname "$0")" && pwd)"

# Replace older generated entries, then add the current scripts path.
if [ -f "$BASHRC" ]; then
  sed -i '/dev_env\/scripts/d' "$BASHRC"
  printf '\nexport PATH="$PATH:%s"\n' "$SCRIPTS_PATH" >> "$BASHRC"
else
  printf 'export PATH="$PATH:%s"\n' "$SCRIPTS_PATH" > "$BASHRC"
fi

if [ -f "$ZSHRC" ]; then
  sed -i '/dev_env\/scripts/d' "$ZSHRC"
  printf '\nexport PATH="$PATH:%s"\n' "$SCRIPTS_PATH" >> "$ZSHRC"
else
  printf 'export PATH="$PATH:%s"\n' "$SCRIPTS_PATH" > "$ZSHRC"
fi
