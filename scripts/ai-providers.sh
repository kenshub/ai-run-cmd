#!/bin/bash

# === OpenAI ===
function ai_call_openai() {
  local prompt="$1"
  # Escape the prompt for JSON
  local escaped_prompt=$(echo "$prompt" | jq -Rs .)
  
  curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "'"${OPENAI_MODEL:-gpt-3.5-turbo}"'",
      "messages": [{"role": "user", "content": '"$escaped_prompt"'}],
      "max_tokens": 300
    }'
}

# === Ollama (Local) ===
function ai_call_ollama() {
  local prompt="$1"
  # For Ollama, we need to ensure newlines are properly passed
  # Use printf to ensure proper formatting
  printf "%s" "$prompt" | ollama run "${OLLAMA_MODEL:-mistral}"
}

# === Anthropic (Claude) ===
function ai_call_anthropic() {
  local prompt="$1"
  # Escape the prompt for JSON
  local escaped_prompt=$(echo "$prompt" | jq -Rs .)
  
  curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "'"${CLAUDE_MODEL:-claude-3-opus}"'",
      "max_tokens": 300,
      "messages": [{"role": "user", "content": '"$escaped_prompt"'}]
    }'
}

# === Mistral API ===
function ai_call_mistral() {
  local prompt="$1"
  # Escape the prompt for JSON
  local escaped_prompt=$(echo "$prompt" | jq -Rs .)
  
  curl -s https://api.mistral.ai/v1/chat/completions \
    -H "Authorization: Bearer $MISTRAL_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "'"${MISTRAL_MODEL:-mistral-tiny}"'",
      "messages": [{"role": "user", "content": '"$escaped_prompt"'}]
    }'
}

# === Groq ===
function ai_call_groq() {
  local prompt="$1"
  # Escape the prompt for JSON
  local escaped_prompt=$(echo "$prompt" | jq -Rs .)
  
  curl -s https://api.groq.com/openai/v1/chat/completions \
    -H "Authorization: Bearer $GROQ_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "'"${GROQ_MODEL:-llama3-70b}"'",
      "messages": [{"role": "user", "content": '"$escaped_prompt"'}]
    }'
}

# Function to set the AI provider
set_provider() {
  local provider="$1"
  case "$provider" in
    openai|ollama|anthropic|mistral|groq)
      export AI_PROVIDER="$provider"
      echo "✅ AI_PROVIDER set to $provider"
      ;;
    *)
      echo "❌ Invalid AI provider: $provider"
      list_providers
      return 1
      ;;
  esac
}

# Function to list available AI providers
list_providers() {
  echo "Available AI providers:"
  echo "  - openai"
  echo "  - ollama"
  echo "  - anthropic"
  echo "  - mistral"
  echo "  - groq"
}

# Function to handle the provider command
provider() {
  if [ -z "$1" ]; then
    list_providers
  else
    set_provider "$1"
  fi
}
