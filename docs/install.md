## 🧰 Manual Setup
If you prefer control.

1. Clone the repo:

```bash
git clone https://github.com/kenshub/ai-run-cmd.git ~/ai-run-cmd
```

2. Create and configure your `.env`:

```bash
cp ~/ai-run-cmd/.env.example ~/ai-run-cmd/.env
nano ~/ai-run-cmd/.env
```

3. Safely source the script in your shell config:

```bash
[ -f ~/ai-run-cmd/ai.sh ] && source ~/ai-run-cmd/ai.sh
```

4. Reload your shell:

```bash
source ~/.bashrc  # or source ~/.zshrc
