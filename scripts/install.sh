#!/bin/bash
set -e

echo "📦 Installing AI RUN CMD..."

# Check if folder exists
if [ -d ~/ai-run-cmd ]; then
  echo "📁 ~/ai-run-cmd already exists."

  if [ -d ~/ai-run-cmd/.git ]; then
    echo "🔄 Updating existing repo via git..."
    git -C ~/ai-run-cmd pull
  else
    echo "OK, not a git repo, so we will not be able to auto-update."
  fi
else
  if command -v git &> /dev/null; then
    echo "Cloning repo via git..."
    git clone https://github.com/kenshub/ai-run-cmd.git ~/ai-run-cmd
  else
    echo "git not found. Please install git or download the zip and run this script again."
    exit 1
  fi
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
  user_context="Act like a terminal assistant. I'm using $user_os and $user_shell. Always respond with full terminal commands I can run inside ticks or quotes. No explanations unless I ask. If it's unsafe, give a warning."
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

# Function to install packages
install_packages() {
  local package_manager=$1
  shift
  local packages=("$@")
  case $package_manager in
    apt) sudo apt-get install -y "${packages[@]}" ;;
    dnf) sudo dnf install -y "${packages[@]}" ;;
    pacman) sudo pacman -S --noconfirm "${packages[@]}" ;;
    apk) sudo apk add "${packages[@]}" ;;
    brew) brew install "${packages[@]}" ;;
    *)
      echo "Unsupported package manager: $package_manager"
      return 1
      ;;
  esac
}

missing=()
for cmd in jq fzf curl git; do
  if ! command -v $cmd &> /dev/null; then
    missing+=($cmd)
  fi
done

if [ ${#missing[@]} -ne 0 ]; then
  echo "⚠️ Missing dependencies: ${missing[*]}"
  echo "👉 Attempting to install missing dependencies..."

  # Detect OS and package manager
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt-get &>/dev/null; then
      install_packages apt "${missing[@]}"
    elif command -v dnf &>/dev/null; then
      install_packages dnf "${missing[@]}"
    elif command -v pacman &>/dev/null; then
      install_packages pacman "${missing[@]}"
    elif command -v apk &>/dev/null; then
      install_packages apk "${missing[@]}"
    else
      echo "Could not detect package manager on Linux. Please install the following packages manually: ${missing[*]}"
    fi
  else
    echo "Could not detect package manager on Linux. Please install the following packages manually: ${missing[*]}"
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      install_packages brew "${missing[@]}"
    else
      echo "Homebrew not found. Please install Homebrew first, then install the following packages manually: ${missing[*]}"
    fi
else
    echo "Homebrew not found. Please install Homebrew first, then install the following packages manually: ${missing[*]}"
  elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "On Windows, please install 'jq' manually."
    echo "Download it from https://jqlang.org/download/"
    echo "Then, add the executable to your system's PATH."
    echo "Alternatively, if you use Chocolatey, you can run: choco install jq"
  else
    echo "Unsupported OS: $OSTYPE. Please install the following packages manually: ${missing[*]}"
  fi
fi

  # Verify installation
  post_install_missing=()
  for cmd in "${missing[@]}"; do
    if ! command -v $cmd &> /dev/null; then
      post_install_missing+=($cmd)
    fi
  done

  if [ ${#post_install_missing[@]} -ne 0 ]; then
    echo "Failed to install: ${post_install_missing[*]}. Please install them manually."
  else
    echo "✅ All dependencies are now installed."
  fi
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
