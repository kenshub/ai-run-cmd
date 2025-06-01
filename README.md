# 🎤 ai-run-dmc

![AI-Run-DMC Logo](img/logos/ai_run_cmd_256x256.png)

A fun and functional terminal AI assistant using ChatGPT or local models via Ollama.
Just type `ai do something` or `ail do it offline` and let DMC help you drop command-line hits.

## 🚀 Features

- `ai`: Cloud AI (OpenAI GPT-3.5 or GPT-4)
- `ail`: Local AI (Ollama models like Mistral, LLaMA3, etc.)
- Fuzzy command picker with `fzf`
- Safe copy/run/exit prompt
- No bloat. Just bash and brains.

## 📦 Install

```bash
curl -s https://raw.githubusercontent.com/YOURUSERNAME/ai-run-dmc/main/ai.sh >> ~/.bashrc
source ~/.bashrc
```

## 🔑 Setup

Create a `.env` file:

```env
OPENAI_API_KEY=your-api-key
OLLAMA_MODEL=mistral
```

## 🍻 Buy Me a Beer

If this helped, [buy me a coffee](https://www.buymeacoffee.com/YOURUSERNAME) or just star the repo!
