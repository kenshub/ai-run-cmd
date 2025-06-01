#!/bin/bash
set -e

echo "📦 Installing AI RUN CMD..."

git clone https://github.com/kenshub/ai-run-cmd.git ~/ai-run-cmd

cp ~/ai-run-cmd/.env.example ~/ai-run-cmd/.env

# Detect shell rc
if [ -n "$ZSH_VERSION" ]; then
  SHELL_RC="$HOME/.zshrc"
else
  SHELL_RC="$HOME/.bashrc"
fi

SOURCE_LINE='[ -f ~/ai-run-cmd/ai.sh ] && source ~/ai-run-cmd/ai.sh'

if ! grep -Fxq "$SOURCE_LINE" "$SHELL_RC"; then
  echo "$SOURCE_LINE" >> "$SHELL_RC"
  echo "✅ Added to $SHELL_RC"
fi

echo "✅ Installed! Reload your shell or run:"
echo "   source $SHELL_RC"
