# 🎤 AI RUN CMD


![AI-Run-DMC Logo](img/logos/ai_run_cmd_256x256.png)

A fun and functional terminal AI assistant using ChatGPT or local models via Ollama.
Just type `ai do something` or `ail do it offline` and let DMC help you drop command-line hits.

---

## 🚀 Features

- `ai`: Cloud AI (OpenAI GPT-3.5 or GPT-4)
- `ail`: Local AI (Ollama models like Mistral, LLaMA3, etc.)
- Fuzzy command picker with `fzf`
- Safe copy/run/exit prompt
- No bloat. Just bash and brains.

---

## 🛠 Installation

### ✅ Quick One-Liner

```bash
bash <(curl -s https://raw.githubusercontent.com/YOURUSERNAME/ai-run-dmc/main/install.sh)
```

> This clones the repo, sets up `.env`, and updates your `.bashrc` or `.zshrc`.

---

### 🧰 Manual Setup
If you prefer control.

1. Clone the repo:

```bash
git clone https://github.com/YOURUSERNAME/ai-run-dmc.git ~/ai-run-dmc
```

2. Create and configure your `.env`:

```bash
cp ~/ai-run-dmc/.env.example ~/ai-run-dmc/.env
nano ~/ai-run-dmc/.env
```

3. Safely source the script in your shell config:

```bash
[ -f ~/ai-run-dmc/ai.sh ] && source ~/ai-run-dmc/ai.sh
```

4. Reload your shell:

```bash
source ~/.bashrc  # or source ~/.zshrc
```

---

## 🧪 Usage

```bash
ai restart apache
ai run docker prune
ai list containers
```

- `[r]` Run it
- `[c]` Copy it
- `[x]` Exit

---

## ☕ Buy Me a Coffee

If this helped you out:

[Buy me a coffee](https://buymeacoffee.com/YOURUSERNAME)

Or just ⭐ the repo and tell a friend.
