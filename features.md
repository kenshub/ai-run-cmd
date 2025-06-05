## ✨ Features and Capabilities

AI Run CMD is a terminal assistant that helps you generate and execute commands using AI. It supports both cloud-based and local AI models.

### 🚀 Key Features

-   **Unified AI Interface (`ai`):** A single command that supports both cloud-based and local AI models.
-   **Multiple AI Providers:** Supports OpenAI, Ollama (local), Anthropic, Mistral, and Groq.
-   **Model Selection:** Choose your preferred AI provider and model through environment variables.
-   **Fuzzy Command Picker:** Uses `fzf` to provide an interactive interface for selecting commands from the AI's suggestions.
-   **Safe Execution:** Prompts you to confirm before running any command, preventing accidental execution of potentially harmful commands.
-   **Copy to Clipboard:** Easily copy the generated command to your clipboard for later use.
-   **Lightweight and Simple:** Implemented in bash with minimal dependencies.

### ⚙️ Configuration

The following environment variables can be used to configure AI Run CMD:

-   `AI_PROVIDER`: The AI provider to use. Can be `openai`, `ollama`, `anthropic`, `mistral`, or `groq`. Defaults to `openai`.
-   `OPENAI_API_KEY`: Your OpenAI API key. Required when using the OpenAI provider.
-   `OPENAI_MODEL`: The OpenAI model to use. Defaults to `gpt-3.5-turbo`.
-   `OLLAMA_MODEL`: The Ollama model to use when `AI_PROVIDER` is set to `ollama`. Defaults to `mistral`.
-   `ANTHROPIC_API_KEY`: Your Anthropic API key. Required when using the Anthropic provider.
-   `CLAUDE_MODEL`: The Claude model to use. Defaults to `claude-3-opus`.
-   `MISTRAL_API_KEY`: Your Mistral API key. Required when using the Mistral provider.
-   `MISTRAL_MODEL`: The Mistral model to use. Defaults to `mistral-tiny`.
-   `GROQ_API_KEY`: Your Groq API key. Required when using the Groq provider.
-   `GROQ_MODEL`: The Groq model to use. Defaults to `llama3-70b`.
-   `DEFAULT_ACTION`: The default action to take when a command is selected. Can be `run`, `copy`, or `ask`. Defaults to `ask`.
-   `DEBUG_AI`: Enable debug mode. Set to `1` to enable.

### 📚 Supported Models

AI Run CMD supports a variety of AI models through different providers:

-   OpenAI:
    -   GPT-3.5-turbo (default)
    -   GPT-4
-   Ollama (Local):
    -   Mistral (default)
    -   Llama2
    -   And other models supported by Ollama
-   Anthropic:
    -   Claude-3-opus (default)
-   Mistral:
    -   mistral-tiny (default)
-   Groq:
    -   llama3-70b (default)

To use a specific provider and model, set the appropriate environment variables:

```bash
# Use OpenAI with GPT-4
export AI_PROVIDER=openai
export OPENAI_MODEL=gpt-4
ai "Write a haiku about the ocean"

# Use Ollama with Llama2
export AI_PROVIDER=ollama
export OLLAMA_MODEL=llama2
ai "Write a haiku about the ocean"
