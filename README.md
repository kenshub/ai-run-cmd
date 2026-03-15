# 🎤 AI RUN CMD


![AI-Run-CMD Logo](img/logos/ai_run_cmd_256x256.png)

A fun and functional terminal AI assistant using ChatGPT, Claude, or local models via Ollama.
Just type `ai do something` and let DMC help you drop command-line hits. Works with cloud-based and local AI models on Linux, macOS, and Windows (WSL).

---

## 🚀 Features

See [features.md](features.md) for a complete list of features and capabilities.

---

## 🛠 Installation

### Linux / macOS

```bash
bash <(curl -s https://raw.githubusercontent.com/kenshub/ai-run-cmd/main/scripts/install.sh)
```

> Clones the repo, installs dependencies, sets up `.env`, and updates your `.bashrc` or `.zshrc`.
> On macOS, Homebrew will be installed automatically if not already present.

### Windows (WSL)

Download and run `install.ps1` in PowerShell:

```powershell
irm https://raw.githubusercontent.com/kenshub/ai-run-cmd/main/install.ps1 | iex
```

> Installs WSL with Ubuntu if needed (requires a reboot), then runs the standard installer inside WSL.

---

See [install.md](install.md) for manual setup instructions.

---

## 🤖 AI Providers

| Provider | Requires |
|---|---|
| OpenAI (default) | API key |
| Anthropic (Claude) | API key |
| Groq | API key |
| Mistral | API key |
| Google Gemini | API key |
| Ollama (local) | No key — runs on your machine |

Switch providers anytime:
```bash
ai provider ollama
ai provider openai
```

---

## 💻 Local LLM (No API Key)

Run AI entirely on your machine — no internet or API key required:

```bash
ai install-local
```

This installs [Ollama](https://ollama.com) and lets you choose a model:

| Model | Size | Best for |
|---|---|---|
| `qwen2.5:0.5b` | ~400MB | Fastest, everyday commands |
| `llama3.2:1b` | ~1.3GB | Good balance |
| `phi3:mini` | ~2.2GB | More capable responses |

---

## 🧪 Usage

```bash
ai restart apache
ai run docker prune
ai list files by size
```

Special commands:
```bash
ai explain tar -czpf         # explain what a command does
ai rap hard drive space       # get the answer in rap format
ai install-local              # set up a local LLM
ai provider ollama            # switch AI provider
ai debug on                   # enable debug output
```

---

## ☕ Buy Me a Coffee

If this helped you out:

[Buy me a coffee](https://buymeacoffee.com/uken)

Or just ⭐ the repo and tell a friend.
