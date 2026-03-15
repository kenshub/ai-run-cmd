#!/bin/bash
set -e

echo "📦 Installing AI RUN CMD v0.6..."

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
  echo "AI_OS=\"$user_os\"" >> ~/ai-run-cmd/.env
  echo "AI_SHELL=\"$user_shell\"" >> ~/ai-run-cmd/.env
  user_context="Act like a terminal assistant. I'm using $user_os and $user_shell. Always respond with full terminal commands I can run inside ticks or quotes. No explanations unless I ask. If it's unsafe, give a warning."
  echo "AI_CONTEXT_ENVIRONMENT=\"$user_context\"" >> ~/ai-run-cmd/.env
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

# sed -i compatibility (macOS requires sed -i '', Linux uses sed -i)
portable_sed_i() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Detect WSL
IS_WSL=0
if [[ "$OSTYPE" == "linux-gnu"* ]] && grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=1
fi

missing=()
for cmd in jq fzf curl git; do
  if ! command -v $cmd &> /dev/null; then
    missing+=($cmd)
  fi
done

if [ ${#missing[@]} -ne 0 ]; then
  echo "⚠️ Missing dependencies: ${missing[*]}"
  echo "👉 Attempting to install missing dependencies..."

  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
      echo "Homebrew not found. Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    if command -v brew &>/dev/null; then
      install_packages brew "${missing[@]}"
    else
      echo "Homebrew installation failed. Please install manually: ${missing[*]}"
    fi
  elif [[ $IS_WSL -eq 1 ]]; then
    echo "WSL detected."
    if command -v apt-get &>/dev/null; then
      install_packages apt "${missing[@]}"
    else
      echo "Could not detect package manager in WSL. Please install manually: ${missing[*]}"
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt-get &>/dev/null; then
      install_packages apt "${missing[@]}"
    elif command -v dnf &>/dev/null; then
      install_packages dnf "${missing[@]}"
    elif command -v pacman &>/dev/null; then
      install_packages pacman "${missing[@]}"
    elif command -v apk &>/dev/null; then
      install_packages apk "${missing[@]}"
    else
      echo "Could not detect package manager on Linux. Please install manually: ${missing[*]}"
    fi
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]]; then
    echo "On Windows/Git Bash, please use WSL for the best experience."
    echo "Or install manually with Chocolatey: choco install jq fzf curl git"
  else
    echo "Unsupported OS: $OSTYPE. Please install manually: ${missing[*]}"
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

# Only ask for preferences if we created a new .env file
if [ $ENV_EXISTS -eq 0 ]; then
  # Ask you for your preferred AI provider
  echo "Available AI providers: openai, ollama, anthropic, mistral, groq, google"
  read -r -p "Please enter your preferred AI provider (default: openai): " preferred_provider
  preferred_provider="${preferred_provider:-openai}"

  # Update the .env file with your preferred provider
  portable_sed_i "s/^AI_PROVIDER=.*/AI_PROVIDER=${preferred_provider}/" ~/ai-run-cmd/.env

  # Ask for model based on provider
  case "$preferred_provider" in
    openai)
      read -r -p "Please enter your preferred OpenAI model (default: gpt-3.5-turbo): " preferred_model
      preferred_model="${preferred_model:-gpt-3.5-turbo}"
      portable_sed_i "s/^OPENAI_MODEL=.*/OPENAI_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
    ollama)
      read -r -p "Please enter your preferred Ollama model (default: mistral): " preferred_model
      preferred_model="${preferred_model:-mistral}"
      portable_sed_i "s/^OLLAMA_MODEL=.*/OLLAMA_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
    anthropic)
      read -r -p "Please enter your preferred Claude model (default: claude-3-opus): " preferred_model
      preferred_model="${preferred_model:-claude-3-opus}"
      portable_sed_i "s/^CLAUDE_MODEL=.*/CLAUDE_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
    mistral)
      read -r -p "Please enter your preferred Mistral model (default: mistral-tiny): " preferred_model
      preferred_model="${preferred_model:-mistral-tiny}"
      portable_sed_i "s/^MISTRAL_MODEL=.*/MISTRAL_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
    groq)
      read -r -p "Please enter your preferred Groq model (default: llama3-70b): " preferred_model
      preferred_model="${preferred_model:-llama3-70b}"
      portable_sed_i "s/^GROQ_MODEL=.*/GROQ_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
    google)
      read -r -p "Please enter your preferred Google model (default: gemini-pro): " preferred_model
      preferred_model="${preferred_model:-gemini-pro}"
      portable_sed_i "s/^GOOGLE_MODEL=.*/GOOGLE_MODEL=${preferred_model}/" ~/ai-run-cmd/.env
      ;;
  esac
fi

echo "✅ Installation complete!"
echo "👉 Run: source $SHELL_RC  (or open a new terminal)"
