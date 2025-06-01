#!/bin/bash
set -e

echo "📦 Installing AI RUN CMD..."

git clone https://github.com/YOURUSERNAME/ai-run-dmc.git ~/ai-run-dmc

cp ~/ai-run-dmc/.env.example ~/ai-run-dmc/.env

# Detect shell rc
if [ -n "$ZSH_VERSION" ]; then
  SHELL_RC="$HOME/.zshrc"
else
  SHELL_RC="$HOME/.bashrc"
fi

SOURCE_LINE='[ -f ~/ai-run-dmc/ai.sh ] && source ~/ai-run-dmc/ai.sh'

if ! grep -Fxq "$SOURCE_LINE" "$SHELL_RC"; then
  echo "$SOURCE_LINE" >> "$SHELL_RC"
  echo "✅ Added to $SHELL_RC"
fi

echo "✅ Installed! Reload your shell or run:"
echo "   source $SHELL_RC"
