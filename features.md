## ✨ Features and Capabilities

AI Run CMD is a terminal assistant that helps you generate and execute commands using AI. It supports both cloud-based and local AI models.

### 🚀 Key Features

-   **Cloud AI (`ai`):** Utilizes OpenAI's GPT-3.5-turbo (default) or other models like GPT-4 for generating commands. Requires an OpenAI API key.
-   **Local AI (`ail`):** Leverages Ollama to run local AI models like Mistral, Llama2, and more. No API key required.
-   **Model Selection:** Choose your preferred AI model during installation or specify it directly in the command.
-   **Fuzzy Command Picker:** Uses `fzf` to provide an interactive interface for selecting commands from the AI's suggestions.
-   **Safe Execution:** Prompts you to confirm before running any command, preventing accidental execution of potentially harmful commands.
-   **Copy to Clipboard:** Easily copy the generated command to your clipboard for later use.
-   **Lightweight and Simple:** Implemented in bash with minimal dependencies.

### ⚙️ Configuration

The following environment variables can be used to configure AI Run CMD:

-   `OPENAI_API_KEY`: Your OpenAI API key. Required for using the `ai` command.
-   `OPENAI_MODEL`: The OpenAI model to use. Defaults to `gpt-3.5-turbo`.
-   `OLLAMA_MODEL`: The Ollama model to use. Defaults to `mistral`.
-   `DEFAULT_ACTION`: The default action to take when a command is selected. Can be `run`, `copy`, or `exit`.
-   `DEBUG_AI`: Enable debug mode. Set to `1` to enable.

### 📚 Supported Models

AI Run CMD supports a variety of AI models, including:

-   OpenAI:
    -   GPT-3.5-turbo
    -   GPT-4
-   Ollama:
    -   Mistral
    -   Llama2

You can specify the model to use by passing it as the first argument to the `ai` or `ail` command. For example:

```bash
ai gpt-4 "Write a haiku about the ocean"
ail llama2 "Write a haiku about the ocean"
