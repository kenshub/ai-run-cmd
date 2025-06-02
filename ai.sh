#################################
# AI RUN CMD terminal assistant #
#################################

#  ----------------------------------------------------------------------------
#  "THE BEER-WARE LICENSE" (Revision 42):
#  As long as you retain this notice you can do whatever you want with this
#  stuff. If we meet some day, and you think this stuff is worth it, you can
#  buy me a beer in return. – Ken
#  ----------------------------------------------------------------------------

# Load .env if available
[ -f .env ] && export $(grep -v '^#' .env | xargs)

# Fallback defaults
OPENAI_MODEL=${OPENAI_MODEL:-gpt-3.5-turbo}
OLLAMA_MODEL=${OLLAMA_MODEL:-mistral}
DEFAULT_ACTION=${DEFAULT_ACTION:-ask}
DEBUG_AI=${DEBUG_AI:-0}


function ai() {
  local prompt="$*"
  local api_key="${OPENAI_API_KEY:-YOUR_API_KEY_HERE}"
  local temp_full="/tmp/ai_full.json"
  local temp_response="/tmp/ai_response.txt"
  local temp_commands="/tmp/ai_commands.txt"

  if [ "$api_key" = "YOUR_API_KEY_HERE" ]; then
    echo "❌ Set your API key with export OPENAI_API_KEY."
    return 1
  fi

  local full_response=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $api_key" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "$OPENAI_MODEL",
      "messages": [{"role": "user", "content": "'"$prompt"'"}],
      "max_tokens": 300
    }')

  echo "$full_response" > "$temp_full"
  local message=$(echo "$full_response" | jq -r '.choices[0].message.content // empty')
  if [ -z "$message" ]; then
    echo "❌ Failed to get a valid response. See $temp_full"
    return 1
  fi

  echo "$message" > "$temp_response"
  echo "$message" | grep -E '^(\s*)(sudo|systemctl|service|curl|docker|npm|yarn|git|echo|rm|cp|mv|cd)' > "$temp_commands"

  local selected=$(cat "$temp_commands" | fzf --prompt="Pick a command: " --preview="echo {}")
  if [ -z "$selected" ]; then
    echo "⚠️ No command selected."
    return 1
  fi

  echo -e "\n➡️ Selected:\n$selected"
  echo -e "Choose an action:\n  [r] Run  [c] Copy to clipboard  [x] Exit"
  read -n1 -rp "> " action
  echo

  case "$action" in
    r|R)
      echo -e "\n▶️ Running:\n$selected"
      eval "$selected"
      ;;
    c|C)
      echo "$selected" | xclip -selection clipboard
      echo "📋 Copied to clipboard."
      ;;
    x|X|*)
      echo "❌ Exiting without action."
      ;;
  esac
}

# Local AI via Ollama
function ail() {
  local prompt="$*"
  local model="${OLLAMA_MODEL:-mistral}"
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

  case "$action" in
    r|R)
      echo -e "\n▶️ Running:\n$selected"
      eval "$selected"
      ;;
    c|C)
      echo "$selected" | xclip -selection clipboard
      echo "📋 Copied to clipboard."
      ;;
    x|X|*)
      echo "❌ Exiting without action."
      ;;
  esac
}
