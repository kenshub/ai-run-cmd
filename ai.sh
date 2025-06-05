#!/bin/bash

#  ----------------------------------------------------------------------------
#  "THE BEER-WARE LICENSE" (Revision 42):
#  As long as you retain this notice you can do whatever you want with this
#  stuff. If we meet some day, and you think this stuff is worth it, you can
#  buy me a beer in return. – Ken
#  ----------------------------------------------------------------------------

# === Load .env if available ===
if [ -f ~/ai-run-cmd/.env ]; then
  # Load environment variables while preserving quotes and special characters
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [ -z "$line" ]; then
      continue
    fi
    
    # Extract variable name and value
    if [[ "$line" =~ ^([A-Za-z0-9_]+)=(.*)$ ]]; then
      var_name="${BASH_REMATCH[1]}"
      var_value="${BASH_REMATCH[2]}"
      
      # Remove quotes if present
      if [[ "$var_value" =~ ^\"(.*)\"$ ]]; then
        var_value="${BASH_REMATCH[1]}"
      fi
      
      # Export the variable
      export "$var_name=$var_value"
    fi
  done < ~/ai-run-cmd/.env
fi

# Set defaults if not provided
OPENAI_MODEL=${OPENAI_MODEL:-gpt-3.5-turbo}
OLLAMA_MODEL=${OLLAMA_MODEL:-mistral}
DEFAULT_ACTION=${DEFAULT_ACTION:-ask}
DEBUG_AI=${DEBUG_AI:-0}
AI_PROVIDER=${AI_PROVIDER:-openai}

# Load provider functions
[ -f ~/ai-run-cmd/ai-providers.sh ] && source ~/ai-run-cmd/ai-providers.sh

# === Spinner function ===
spinner() {
  local pid=$1
  local delay=0.1
  local provider=$2
  local model=$3
  local spinstr='◐◓◑◒'
  local info=" $provider ($model)"
  
  tput civis  # Hide cursor
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " %c%s" "$spinstr" "$info"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\r"
  done
  printf "    \r"
  tput cnorm  # Show cursor
}

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
  
  # Fallback for command-looking lines (always enabled)
  [[ $debug -eq 1 ]] && echo "🔍 Extracting fallback shell-looking commands..."
  grep -E '^\s*(sudo|systemctl|service|curl|docker|npm|yarn|git|echo|rm|cp|mv|cd|apt|apt-get|yum|dnf|pacman|brew|python|python3|node|go|java|gcc|make|./|sh|bash|zsh|find|grep|awk|sed|cat|ls|mkdir|touch|chmod|chown)' "$temp_response" >> "$temp_extracted"

  # Check if any commands were extracted
  if [ ! -s "$temp_extracted" ]; then
    # If no commands were found, check if the response starts with a command
    [[ $debug -eq 1 ]] && echo "🔍 No commands found. Checking if response starts with a command..."
    
    # Get the first non-empty line of the response
    local first_line=$(grep -v '^$' "$temp_response" | head -n 1)
    
    # Check if the first line looks like a command (starts with common command prefixes)
    if [[ "$first_line" =~ ^[[:space:]]*(sudo|systemctl|service|curl|docker|npm|yarn|git|echo|rm|cp|mv|cd|apt|apt-get|yum|dnf|pacman|brew|python|python3|node|go|java|gcc|make|./|sh|bash|zsh|find|grep|awk|sed|cat|ls|mkdir|touch|chmod|chown|tar) ]]; then
      [[ $debug -eq 1 ]] && echo "✅ Found command at start of response: $first_line"
      echo "$first_line" >> "$temp_extracted"
    fi
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
  # Check if the command is to toggle debug mode
  if [ "$1" = "debug" ]; then
    local debug_value="$2"
    case "$debug_value" in
      on|ON|true|TRUE|1|yes|YES|y|Y)
        export DEBUG_AI=1
        echo "🐛 Debug mode enabled"
        ;;
      off|OFF|false|FALSE|0|no|NO|n|N)
        export DEBUG_AI=0
        echo "🐛 Debug mode disabled"
        ;;
      *)
        echo "ℹ️ Current debug mode: $([ "$DEBUG_AI" = "1" ] && echo "enabled" || echo "disabled")"
        echo "Usage: ai debug [on|off|true|false|1|0|yes|no]"
        ;;
    esac
    return 0
  fi

  # Debug: Show the raw AI_CONTEXT variable
  if [ "$DEBUG_AI" = "1" ]; then
    echo "[DEBUG] AI_CONTEXT: '$AI_CONTEXT'"
  fi

  # Format the prompt properly with newlines
  local formatted_prompt
  printf -v formatted_prompt "%s\n\n%s" "$AI_CONTEXT" "$*"
  
  local temp_full="/tmp/ai_full.json"
  local temp_response="/tmp/ai_response.txt"
  local temp_commands="/tmp/ai_commands.txt"
  local temp_prompt="/tmp/ai_prompt.txt"
  
  # Save the prompt for debugging
  echo "$formatted_prompt" > "$temp_prompt"

  # Get the current model based on provider
  local current_model
  case "$AI_PROVIDER" in
    openai)    current_model="$OPENAI_MODEL" ;;
    ollama)    current_model="$OLLAMA_MODEL" ;;
    anthropic) current_model="Claude" ;;
    mistral)   current_model="Mistral" ;;
    groq)      current_model="Groq" ;;
    *)         current_model="Unknown" ;;
  esac

  # Create a temporary file for the response
  local temp_response_file=$(mktemp)
  
  # Run the API call in the background
  case "$AI_PROVIDER" in
    openai)    ai_call_openai "$formatted_prompt" > "$temp_response_file" & ;;
    ollama)    ai_call_ollama "$formatted_prompt" > "$temp_response_file" & ;;
    anthropic) ai_call_anthropic "$formatted_prompt" > "$temp_response_file" & ;;
    mistral)   ai_call_mistral "$formatted_prompt" > "$temp_response_file" & ;;
    groq)      ai_call_groq "$formatted_prompt" > "$temp_response_file" & ;;
    *)
      echo "❌ Unknown AI_PROVIDER: $AI_PROVIDER"
      return 1
      ;;
  esac
  
  # Get the PID of the background process
  local api_pid=$!
  
  # Start the spinner
  spinner $api_pid "$AI_PROVIDER" "$current_model"
  
  # Wait for the background process to complete
  wait $api_pid
  
  # Read the response from the temporary file
  response=$(cat "$temp_response_file")
  rm -f "$temp_response_file"

  echo "$response" > "$temp_full"

  # Extract message depending on provider format
  if [[ "$AI_PROVIDER" == "ollama" ]]; then
    message="$response"
  else
    # Try different JSON paths to extract the message content
    message=$(echo "$response" | jq -r '.choices[0].message.content // .content // .choices[0].text // .message // empty')
    
    # Debug: Show the extracted message
    if [ "$DEBUG_AI" = "1" ]; then
      echo "[DEBUG] Extracted message:"
      echo "$message"
    fi
  fi

  echo "$message" > "$temp_response"
  extract_commands "$temp_response" "$temp_commands" "$DEBUG_AI"

  if [ "$DEBUG_AI" = "1" ]; then
    echo -e "\n[DEBUG] Full response saved to: $temp_full"
    cat "$temp_commands"
  fi

  # Prepare preview content based on debug setting
  local preview_cmd
  if [ "$DEBUG_AI" = "1" ]; then
    preview_cmd="echo -e '=== DEBUG INFO ===\nProvider: $AI_PROVIDER\nModel: $current_model\n\n=== PROMPT ===\n'; cat $temp_prompt; echo -e '\n\n=== RESPONSE ===\n'; cat $temp_response"
  else
    preview_cmd="echo -e '=== RESPONSE ===\n'; cat $temp_response"
  fi

  local selected=$(fzf --prompt="Pick a command: " \
    --preview="$preview_cmd" \
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

# Note: Local AI is now supported through the main ai() function
# by setting AI_PROVIDER=ollama and OLLAMA_MODEL to your desired model
