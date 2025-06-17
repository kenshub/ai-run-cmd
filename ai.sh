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
 AI_CONTEXT_BEHAVIOR=${AI_CONTEXT_BEHAVIOR:-"Act like a terminal assistant."}
 AI_CONTEXT_ENVIRONMENT=${AI_CONTEXT_ENVIRONMENT:-"I'm using Linux Mint and Bash."}
 AI_CONTEXT_FORMAT=${AI_CONTEXT_FORMAT:-"Always respond with full terminal commands. No explanations unless I ask."}
 AI_CONTEXT_WARNING=${AI_CONTEXT_WARNING:-"Warn me if the command is dangerous."}
 

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
 

  # Fallback for command-looking lines (always enabled)
  [[ $debug -eq 1 ]] && echo "🔍 Extracting fallback shell-looking commands..."
  grep -E '^\s*(sudo|systemctl|service|curl|docker|npm|yarn|git|echo|rm|cp|mv|cd|apt|apt-get|yum|dnf|pacman|brew|python|python3|node|go|java|gcc|make|./|sh|bash|zsh|find|grep|awk|sed|cat|ls|mkdir|touch|chmod|chown)' "$temp_response" >> "$temp_extracted"
 

  # Check if any commands were extracted
  if [ ! -s "$temp_extracted" ]; then
  # If no commands were found, check if the response starts with a command
 

  # Get the first non-empty line of the response
  local first_line=$(grep -v '^$' "$temp_response" | head -n 1)
 

  # Check if the first line looks like a command (starts with common command prefixes)
  if [[ "$first_line" =~ ^[[:space:]]*(sudo|systemctl|service|curl|docker|npm|yarn|git|echo|rm|cp|mv|cd|apt|apt-get|yum|dnf|pacman|brew|python|python3|node|go|java|gcc|make|./|sh|bash|zsh|find|grep|awk|sed|cat|ls|mkdir|touch|chmod|chown|tar) ]]; then
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
 

  # Check if the command is to set the provider
  if [ "$1" = "provider" ]; then
    provider "${@:2}"
    return 0
  fi

  # Initialize AI_CONTEXT_ACTION
  AI_CONTEXT_ACTION=""

  # Easter egg: if the user types "rap", add a bit of fun to the context
  if [ "$1" = "rap" ]; then
    # Randomly choose between two rap-style prompts
    if [ $((RANDOM % 2)) -eq 0 ]; then
      AI_CONTEXT_ACTION="Respond in a rap style."
    else
      AI_CONTEXT_ACTION="Answer in a rhyme."
    fi
    # Remove "rap" from the arguments
    shift
  fi

  # Explain command
  if [ "$1" = "explain" ]; then
    AI_CONTEXT_ACTION="Explain the command and what it does."
    # Remove "explain" from the arguments
    shift
  fi

  # Assemble the final context
  local final_context="${AI_CONTEXT_BEHAVIOR} ${AI_CONTEXT_ACTION} ${AI_CONTEXT_ENVIRONMENT} ${AI_CONTEXT_FORMAT} ${AI_CONTEXT_WARNING}"
 

  # Debug: Show the raw AI_CONTEXT variable
  if [ "$DEBUG_AI" = "1" ]; then
  echo "[DEBUG] AI_CONTEXT: '$final_context'"
  fi
 

  # Format the prompt properly with newlines
  local formatted_prompt
  printf -v formatted_prompt "%s\n\n%s" "$final_context" "$*"
 

  local temp_full="/tmp/ai_full.json"
  local temp_response="/tmp/ai_response.txt"
  local temp_commands="/tmp/ai_commands.txt"
  local temp_prompt="/tmp/ai_prompt.txt"
 

  # Save the prompt for debugging
  echo "$formatted_prompt" > "$temp_prompt"
 

  # Select provider logic
  case "$AI_PROVIDER" in
  openai)    response=$(ai_call_openai "$formatted_prompt")
  ;;
  ollama)    response=$(ai_call_ollama "$formatted_prompt")
  ;;
  anthropic) response=$(ai_call_anthropic "$formatted_prompt") ;;
  mistral)   response=$(ai_call_mistral "$formatted_prompt") ;;
  groq)      response=$(ai_call_groq "$formatted_prompt") ;;
  *)
  echo "❌ Unknown AI_PROVIDER: $AI_PROVIDER"
  return 1
  ;;
  esac
 

  echo "$response" > "$temp_full"
  echo "[DEBUG] Raw API response: $response"
 

  # Extract message depending on provider format
  if [[ "$AI_PROVIDER" == "ollama" ]]; then
  message="$response"
  else
  # Try different JSON paths to extract the message content
  # Extract message content using bash string manipulation
  message=$(
    if echo "$response" | grep -q '"choices":'; then
      echo "$response" | sed -n 's/.*"choices":.*"content":"\([^"]*\)".*/\1/p'
    elif echo "$response" | grep -q '"content":'; then
      echo "$response" | sed -n 's/.*"content":"\([^"]*\)".*/\1/p'
    elif echo "$response" | grep -q '"choices":.*"text":'; then
      echo "$response" | sed -n 's/.*"choices":.*"text":"\([^"]*\)".*/\1/p'
    elif echo "$response" | grep -q '"message":'; then
      echo "$response" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p'
    else
      echo ""
    fi
  )

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
    # Get the current model based on provider
    local current_model
    case "$AI_PROVIDER" in
    openai)    current_model="$OPENAI_MODEL" ;;
    ollama)    current_model="$OLLAMA_MODEL" ;;
    anthropic) current_model="Claude" ;;
    mistral)   current_model="Mistral" ;;
    groq)      response=$(ai_call_groq "$formatted_prompt") ;;
    *)         current_model="Unknown" ;;
    esac
 

    preview_cmd="echo -e '=== DEBUG INFO ===\nProvider: $AI_PROVIDER\nModel: $current_model\n\n=== PROMPT ===\n'; cat $temp_prompt; echo -e '\n\n=== RESPONSE ===\n'; cat $temp_response"
  else
    preview_cmd="cat $temp_response"
  fi
 

  # Check if fzf is installed
  if command -v fzf &> /dev/null; then
    local selected=$( (cat "$temp_commands"; echo "Exit") | fzf --prompt="Pick a command: " \
    --preview="$preview_cmd" \
    --preview-window=up:70%:wrap)
 

    if [ -z "$selected" ]; then
      echo "⚠️ No command selected."
      return 1
    fi
 

    if [ "$selected" = "Exit" ]; then
      return 0 # Exit the function without printing anything
    fi
  else
    # Use a bash menu as a fallback for fzf
    local commands_array
    local i=1
    while IFS= read -r command; do
      commands_array[$i]="$command"
      i=$((i+1))
    done < "$temp_commands"
    commands_array[$i]="Exit"
 

    echo "Pick a command:"
    for j in $(seq 1 $i); do
      echo "$j) ${commands_array[$j]}"
    done
 

    read -p "Enter your choice (1-$i): " choice
 

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt $i ]; then
      echo "⚠️ Invalid choice."
      return 1
    fi
 

    local selected="${commands_array[$choice]}"
 

    if [ "$selected" = "Exit" ]; then
      return 0 # Exit the function without printing anything
    fi
  fi

  if [ -n "$ZSH_VERSION" ]; then
    # For Zsh, print -z pushes the command to the editing buffer
    print -z "$selected"
  elif [ -n "$TMUX" ]; then
    # If in tmux, send the keys to the pane
    tmux send-keys -l -- "$selected"
  elif [ -n "$STY" ]; then
    # If in GNU Screen, stuff the command into the input buffer
    screen -X stuff "$selected"
  elif [ -n "$BASH_VERSION" ]; then
    # For Bash, use read -e to allow editing
    read -e -i "$selected" -p "Run command: " command_to_run
    history -s "$command_to_run"
    eval "$command_to_run"
  else
    # Fallback for other shells
    echo "$selected"
  fi
 }
 

 # Note: Local AI is now supported through the main ai() function
 # by setting AI_PROVIDER=ollama and OLLAMA_MODEL to your desired model
