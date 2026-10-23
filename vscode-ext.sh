#!/bin/bash
REPO="$(cd "$(dirname "$0")" && pwd)"
f="$REPO/packages/vscode-extensions.txt"
command -v code >/dev/null && [ -f "$f" ] || exit 0
echo "==> VS Code extensions"
while read -r e; do [ -n "$e" ] && code --install-extension "$e" --force; done < "$f"
