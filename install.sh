#!/bin/bash
set -e

echo "📦 Installing AI RUN CMD..."

# Check if folder exists
if [ -d ~/ai-run-cmd ]; then
  echo "📁 ~/ai-run-cmd already exists."

  if [ -d ~/ai-run-cmd/.git ]; then
    echo "🔄 Updating existing repo..."
    git -C ~/ai-run-cmd pull
  else
    echo "⚠️ Folder exists but is not a Git repo. Please move or remove it first."
    exit 1
  fi
else
  git clone https://github.com/kenshub/ai-run-cmd.git ~/ai-run-cmd
fi

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

# Dependency check
echo "🔍 Checking dependencies..."

missing=()
for cmd in jq fzf xclip curl; do
  if ! command -v $cmd &> /dev/null; then
    missing+=($cmd)
  fi
done

if [ ${#missing[@]} -ne 0 ]; then
  echo "⚠️ Missing dependencies: ${missing[*]}"
  echo "👉 You can install them using your system's package manager. For example:"
  echo "   Debian/Ubuntu: sudo apt install ${missing[*]}"
  echo "   Fedora:        sudo dnf install ${missing[*]}"
  echo "   Arch:          sudo pacman -S ${missing[*]}"
  echo "   Alpine:        sudo apk add ${missing[*]}"
  echo "🛠 Please install them manually before using ai/ail."
else
  echo "✅ All dependencies found."
fi

echo "✅ Installation complete! Reload your shell or run:"
echo "   source $SHELL_RC"