#!/bin/bash

#  ----------------------------------------------------------------------------
#  "THE BEER-WARE LICENSE" (Revision 42):
#  As long as you retain this notice you can do whatever you want with this
#  stuff. If we meet some day, and you think this stuff is worth it, you can
#  buy me a beer in return. – Ken
#  ----------------------------------------------------------------------------

# === Load .env if available ===
[ -f ~/ai-run-cmd/.env ] && export $(grep -v '^#' ~/ai-run-cmd/.env | xargs)

# Set defaults if not provided
OPENAI_MODEL=${OPENAI_MODEL:-gpt-3.5-turbo}
OLLAMA_MODEL=${OLLAMA_MODEL:-mistral}
DEFAULT_ACTION=${DEFAULT_ACTION:-ask}
DEBUG_AI=${DEBUG_AI:-0}
AI_PROVIDER=${AI_PROVIDER:-openai}

# Load provider functions
[ -f ~/ai-run-cmd/ai-providers.sh ] && source ~/ai-run-cmd/ai-providers.sh

# === Main AI Function ===
function ai() {
  local prompt="$*"
  local temp_full="/tmp/ai_full.json"
  local temp_response="/tmp/ai_response.txt"
  local temp_commands="/tmp/ai_commands.txt"

  # Select provider logic
  case "$AI_PROVIDER" in
    openai)    response=$(ai_call_openai "$prompt") ;;
    ollama)    response=$(ai_call_ollama "$prompt") ;;
    anthropic) response=$(ai_call_anthropic "$prompt") ;;
    mistral)   response=$(ai_call_mistral "$prompt") ;;
    groq)      response=$(ai_call_groq "$prompt") ;;
    *)
      echo "❌ Unknown AI_PROVIDER: $AI_PROVIDER"
      return 1
      ;;
  esac

  echo "$response" > "$temp_full"

  # Extract message depending on provider format
  if [[ "$AI_PROVIDER" == "ollama" ]]; then
    message="$response"
  else
    message=$(echo "$response" | jq -r '.choices[0].message.content // .content // empty')
  fi

  echo "$message" > "$temp_response"
  echo "$message" | grep -E '^(\s*)(sudo|systemctl|service|curl|docker|npm|yarn|git|echo|rm|cp|mv|cd)' > "$temp_commands"

  if [ "$DEBUG_AI" = "1" ]; then
    echo -e "\n[DEBUG] Full response saved to: $temp_full"
    cat "$temp_commands"
  fi

  local selected=$(cat "$temp_commands" | fzf --prompt="Pick a command: " --preview="echo {}")
  if [ -z "$selected" ]; then
    echo "⚠️ No command selected."
    return 1
  fi

  echo -e "\n➡️ Selected:\n$selected"

  case "$DEFAULT_ACTION" in
    run|RUN)
      eval "$selected"
      ;;
    copy|COPY)
      echo "$selected" | xclip -selection clipboard
      echo "📋 Copied to clipboard."
      ;;
    ask|ASK|*)
      echo -e "Choose an action:\n  [r] Run  [c] Copy to clipboard  [x] Exit"
      read -n1 -rp "> " action
      echo
      case "$action" in
        r|R) eval "$selected" ;;
        c|C) echo "$selected" | xclip -selection clipboard; echo "📋 Copied." ;;
        x|X|*) echo "❌ Exiting." ;;
      esac
      ;;
  esac
}

# Local AI via Ollama
function ail() {
  local model="${1:-mistral}"
  shift
  local prompt="$*"
  local temp_response="/tmp/ail_response.txt"
  local temp_commands="/tmp/ail_commands.txt"

  local response=$(ollama run "$model" "$prompt")
  if [ -z "$response" ]; then
    echo "❌ No response from Ollama."
    return 1
  fi

  echo "$response" > "$temp_response"
  echo "$response" | grep -E '^(\s*)(sudo|systemctl|service|curl|docker|npm|yarn|git|echo|rm|cp|mv|cd)' > "$temp_commands"

  local selected=$(cat "$temp_commands" | fzf --prompt="Pick a command: " --preview="echo {}")
  if [ -z "$selected" ]; then
    echo "⚠️ No command selected."
    return 1
  fi

  echo -e "\n➡️ Selected:\n$selected"
  echo -e "Choose an action:\n  [r] Run  [c] Copy to clipboard  [x] Exit"
  read -n1 -rp "> " action
  echo

  case "$DEFAULT_ACTION" in
    run|RUN)
      eval "$selected"
      ;;
    copy|COPY)
      echo "$selected" | xclip -selection clipboard
      echo "📋 Copied to clipboard."
      ;;
    ask|ASK|*)
      echo -e "Choose an action:\n  [r] Run  [c] Copy to clipboard  [x] Exit"
      read -n1 -rp "> " action
      echo
      case "$action" in
        r|R) eval "$selected" ;;
        c|C) echo "$selected" | xclip -selection clipboard; echo "📋 Copied." ;;
        x|X|*) echo "❌ Exiting." ;;
      esac
      ;;
  esac
}