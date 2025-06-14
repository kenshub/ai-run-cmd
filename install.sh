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

# Check if .env file already exists
ENV_EXISTS=0
if [ -f ~/ai-run-cmd/.env ]; then
  echo "📄 .env file already exists, keeping your existing configuration. Check .env.example for any new config."
  ENV_EXISTS=1
else
  echo "📄 Creating new .env file from example..."
  cp ~/ai-run-cmd/.env.example ~/ai-run-cmd/.env
  echo "🔧 Collecting configuration..."
  read -p "What is your operating system? (e.g. Linux Mint): " user_os
  read -p "What shell do you use? (e.g. bash): " user_shell
  read -p "Optional AI prompt context (press enter for default): " user_context

  echo "AI_OS=\"$user_os\"" >> .env
  echo "AI_SHELL=\"$user_shell\"" >> .env
  user_context="Act like a terminal assistant. I'm using $user_os and $user_shell. Always respond with full terminal commands I can run. No explanations unless I ask. If it's unsafe, give a warning."
  echo "AI_CONTEXT=\"$user_context\"" >> .env



  echo "✅ .env created. Edit it to set your API key and model."
fi



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
  echo "🛠 Please install them manually before using the ai command."
else
  echo "✅ All dependencies found."
fi

# Only ask for preferences if we created a new .env file
if [ $ENV_EXISTS -eq 0 ]; then
  # Ask you for your preferred AI provider
  echo "Available AI providers: openai, ollama, anthropic, mistral, groq"
  read -r -p "Please enter your preferred AI provider (default: openai): " preferred_provider
  preferred_provider="${preferred_provider:-openai}"

  # Update the .env file with your preferred provider
  sed -i "s/^AI_PROVIDER=.*/AI_PROVIDER=${preferred_provider}/" ~/ai-run-cmd/.env

  # Ask for model based on provider
  case "$preferred_provider" in
    openai)
      read -r -p "Please enter your preferred OpenAI model (default: gpt-3.5-turbo): " preferred_model
      preferred_model="${preferred_model:-gpt-3.5-turbo}"
      sed -i "s/^OPENAI_MODEL=.*/OPENAI_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
    ollama)
      read -r -p "Please enter your preferred Ollama model (default: mistral): " preferred_model
      preferred_model="${preferred_model:-mistral}"
      sed -i "s/^OLLAMA_MODEL=.*/OLLAMA_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
    anthropic)
      read -r -p "Please enter your preferred Claude model (default: claude-3-opus): " preferred_model
      preferred_model="${preferred_model:-claude-3-opus}"
      sed -i "s/^CLAUDE_MODEL=.*/CLAUDE_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
    mistral)
      read -r -p "Please enter your preferred Mistral model (default: mistral-tiny): " preferred_model
      preferred_model="${preferred_model:-mistral-tiny}"
      sed -i "s/^MISTRAL_MODEL=.*/MISTRAL_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
    groq)
      read -r -p "Please enter your preferred Groq model (default: llama3-70b): " preferred_model
      preferred_model="${preferred_model:-llama3-70b}"
      sed -i "s/^GROQ_MODEL=.*/GROQ_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
  esac
fi

echo "✅ Installation complete! Reloading shell..."
if [ -n "$ZSH_VERSION" ]; then
  exec zsh
else
  exec bash
fi
