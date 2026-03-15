# AI RUN CMD - Windows PowerShell Bootstrapper
# Run in PowerShell. Requires Windows 10/11 with winget.
# WSL installation may require running as Administrator.

$ErrorActionPreference = "Stop"

Write-Host "AI RUN CMD - Windows Setup" -ForegroundColor Cyan
Write-Host ""

# Check wsl.exe is available
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Host "wsl.exe not found. Please enable WSL via Windows Features or run:" -ForegroundColor Red
    Write-Host "  wsl --install" -ForegroundColor Yellow
    exit 1
}

# Check if WSL has a working default distro
$wslCheck = wsl --status 2>&1
$wslReady = $LASTEXITCODE -eq 0

if (-not $wslReady) {
    Write-Host "WSL is not installed or has no Linux distribution." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Installing WSL with Ubuntu (default)..." -ForegroundColor Cyan
    Write-Host "Note: Administrator privileges may be required." -ForegroundColor Yellow
    Write-Host ""

    wsl --install

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host " REBOOT REQUIRED to complete WSL installation." -ForegroundColor Yellow
    Write-Host " After rebooting, open PowerShell and run:" -ForegroundColor White
    Write-Host ""
    Write-Host "   irm https://raw.githubusercontent.com/kenshub/ai-run-cmd/main/install.ps1 | iex" -ForegroundColor Green
    Write-Host ""
    Write-Host " Or if you downloaded this file:" -ForegroundColor White
    Write-Host "   .\install.ps1" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Yellow
    exit 0
}

Write-Host "WSL is ready." -ForegroundColor Green
Write-Host ""
Write-Host "Running AI RUN CMD installer inside WSL..." -ForegroundColor Cyan
Write-Host ""

wsl bash -c @'
set -e
if ! command -v git &>/dev/null; then
  echo "git not found in WSL. Installing..."
  sudo apt-get update -qq && sudo apt-get install -y git
fi
if [ -d ~/ai-run-cmd/.git ]; then
  echo "Updating existing install..."
  git -C ~/ai-run-cmd pull
else
  git clone https://github.com/kenshub/ai-run-cmd.git ~/ai-run-cmd
fi
bash ~/ai-run-cmd/scripts/install.sh
'@

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Installation failed (exit code $LASTEXITCODE). Check output above." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Done! Open your WSL terminal and try:" -ForegroundColor Green
Write-Host "  ai list files by size" -ForegroundColor Cyan
