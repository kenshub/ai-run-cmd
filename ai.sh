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

# === Extract commands from AI response ===
extract_commands() {
  local temp_response="$1"
  local temp_commands="$2"
  local debug=${3:-0}
  
  [[ $debug -eq 1 ]] && echo "🧠 Starting command extraction..."
  
  # Clear the commands file
  > "$temp_commands"
  
  # Create a temporary file for storing all extracted commands
  local temp_extracted=$(mktemp)
  
  # Extract triple backtick code blocks
  [[ $debug -eq 1 ]] && echo "🔍 Extracting triple-backtick code blocks..."
  
  # This pattern handles triple backticks with or without language specifiers
  # and preserves multiline content
  perl -0777 -ne 'while(/```(?:[a-zA-Z]*\n)?(.*?)```/gs){print "$1\n"}' "$temp_response" >> "$temp_extracted"
  
  # Check if any triple backtick blocks were found
  if [ ! -s "$temp_extracted" ]; then
    # If no triple backticks were found, extract inline single-backtick code
    [[ $debug -eq 1 ]] && echo "🔍 No triple backticks found. Extracting inline backtick commands..."
    
    # This pattern handles inline backticks, avoiding nested backticks
    perl -ne 'while(/`([^`]+)`/g){print "$1\n"}' "$temp_response" >> "$temp_extracted"
  else
    [[ $debug -eq 1 ]] && echo "🔍 Triple backticks found. Skipping inline backtick extraction."
  fi
  
  # Fallback for command-looking lines (optional)
  if [[ $debug -eq 1 ]]; then
    echo "🔍 Extracting fallback shell-looking commands..."
    grep -E '^\s*(sudo|systemctl|service|curl|docker|npm|yarn|git|echo|rm|cp|mv|cd)' "$temp_response" >> "$temp_extracted"
  fi
  
  # Filter, deduplicate, and clean the extracted commands
  [[ $debug -eq 1 ]] && echo "🧼 Deduplicating and cleaning..."
  
  # Sort, remove duplicates, and clean whitespace
  cat "$temp_extracted" | 
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | 
    grep -v '^$' | 
    sort | 
    uniq > "$temp_commands"
  
  # Clean up
  rm -f "$temp_extracted"
  
  [[ $debug -eq 1 ]] && echo "✅ Command extraction complete. Found $(wc -l < "$temp_commands") commands."
  
  # Debug: show extracted commands
  if [[ $debug -eq 1 ]]; then
    echo "📋 Extracted commands:"
    cat "$temp_commands" | while read -r cmd; do
      echo "  - $cmd"
    done
  fi
}

# === Main AI Function ===
function ai() {
  local prompt="${AI_CONTEXT}\n\n$*"
  local temp_full="/tmp/ai_full.json"
  local temp_response="/tmp/ai_response.txt"
  local temp_commands="/tmp/ai_commands.txt"
  local temp_prompt="/tmp/ai_prompt.txt"
  
  # Save the prompt for debugging
  echo -e "$prompt" > "$temp_prompt"

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
  extract_commands "$temp_response" "$temp_commands" "$DEBUG_AI"

  if [ "$DEBUG_AI" = "1" ]; then
    echo -e "\n[DEBUG] Full response saved to: $temp_full"
    cat "$temp_commands"
  fi

  local selected=$(fzf --prompt="Pick a command: " \
    --preview="echo -e '=== PROMPT ===\n'; cat $temp_prompt; echo -e '\n\n=== RESPONSE ===\n'; cat $temp_response" \
    --preview-window=up:wrap < "$temp_commands")

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
  extract_commands "$temp_response" "$temp_commands" 0

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
