#!/bin/bash

install_local_llm() {
  # --- OS Detection ---
  local os_type="linux"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    os_type="mac"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
      os_type="wsl"
    fi
  fi

  echo "Detected OS: $os_type"
  echo ""

  # --- Install Ollama if missing ---
  if ! command -v ollama &>/dev/null; then
    echo "Ollama not found. Installing..."
    if [[ "$os_type" == "mac" ]]; then
      if command -v brew &>/dev/null; then
        brew install ollama
        brew services start ollama
      else
        echo "Homebrew is required to install Ollama on macOS."
        echo "Install Homebrew first: https://brew.sh"
        return 1
      fi
    elif [[ "$os_type" == "linux" || "$os_type" == "wsl" ]]; then
      curl -fsSL https://ollama.com/install.sh | sh
      if ! pgrep -x ollama &>/dev/null; then
        ollama serve &>/dev/null &
        sleep 2
      fi
    else
      echo "Unsupported OS for automatic Ollama install. Visit https://ollama.com"
      return 1
    fi
  else
    echo "Ollama is already installed."
    if [[ "$os_type" == "mac" ]]; then
      brew services start ollama 2>/dev/null || true
    elif [[ "$os_type" == "linux" || "$os_type" == "wsl" ]]; then
      if ! pgrep -x ollama &>/dev/null; then
        ollama serve &>/dev/null &
        sleep 2
      fi
    fi
  fi

  if ! command -v ollama &>/dev/null; then
    echo "Ollama installation failed. Please install manually: https://ollama.com"
    return 1
  fi

  # --- Model Selection ---
  echo ""
  echo "Choose a local model to install:"
  echo "  1) qwen2.5:0.5b  (~400MB)  - Fastest, smallest"
  echo "  2) llama3.2:1b   (~1.3GB)  - Good balance"
  echo "  3) phi3:mini     (~2.2GB)  - More capable"
  echo "  4) Custom        - Enter your own model name"
  echo ""
  read -r -p "Enter choice [1-4] (default: 1): " model_choice
  model_choice="${model_choice:-1}"

  local chosen_model
  case "$model_choice" in
    1) chosen_model="qwen2.5:0.5b" ;;
    2) chosen_model="llama3.2:1b" ;;
    3) chosen_model="phi3:mini" ;;
    4)
      read -r -p "Enter Ollama model name (e.g. mistral, codellama): " chosen_model
      if [[ -z "$chosen_model" ]]; then
        echo "No model name entered. Aborting."
        return 1
      fi
      ;;
    *)
      echo "Invalid choice. Defaulting to qwen2.5:0.5b"
      chosen_model="qwen2.5:0.5b"
      ;;
  esac

  echo ""
  echo "Pulling $chosen_model ..."
  ollama pull "$chosen_model"

  if [ $? -ne 0 ]; then
    echo "Failed to pull '$chosen_model'. Check the model name and try again."
    return 1
  fi

  # --- Update .env ---
  local env_file
  if [ -f ~/ai-run-cmd/.env ]; then
    env_file="$HOME/ai-run-cmd/.env"
  elif [ -f ~/.ai-run-cmd/.env ]; then
    env_file="$HOME/.ai-run-cmd/.env"
  else
    echo "Could not find .env file. Set AI_PROVIDER=ollama and OLLAMA_MODEL=$chosen_model manually."
    return 1
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^AI_PROVIDER=.*/AI_PROVIDER=ollama/" "$env_file"
    sed -i '' "s/^OLLAMA_MODEL=.*/OLLAMA_MODEL=$chosen_model/" "$env_file"
  else
    sed -i "s/^AI_PROVIDER=.*/AI_PROVIDER=ollama/" "$env_file"
    sed -i "s/^OLLAMA_MODEL=.*/OLLAMA_MODEL=$chosen_model/" "$env_file"
  fi

  export AI_PROVIDER=ollama
  export OLLAMA_MODEL="$chosen_model"

  echo ""
  echo "Done! Local LLM configured:"
  echo "  Provider : ollama"
  echo "  Model    : $chosen_model"
  echo ""
  echo "Try it: ai list files in current directory"
}
