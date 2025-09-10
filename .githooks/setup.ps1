# Setup script for git hooks (Windows PowerShell)
# This script installs the pre-commit hook

Write-Host "🔧 Setting up git hooks for CanBussy UI..." -ForegroundColor Cyan

# Get the repository root directory
try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) {
        throw "Not in a git repository"
    }
} catch {
    Write-Host "❌ Error: Not in a git repository" -ForegroundColor Red
    exit 1
}

# Define hook paths
$hooksDir = Join-Path $repoRoot ".githooks"
$gitHooksDir = Join-Path $repoRoot ".git\hooks"
$preCommitHook = Join-Path $hooksDir "pre-commit"
$installedHook = Join-Path $gitHooksDir "pre-commit"

# Check if our hooks directory exists
if (-not (Test-Path $hooksDir)) {
    Write-Host "❌ Error: .githooks directory not found" -ForegroundColor Red
    Write-Host "Please ensure you're in the CanBussy UI project directory" -ForegroundColor Yellow
    exit 1
}

# Create .git/hooks directory if it doesn't exist
if (-not (Test-Path $gitHooksDir)) {
    New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
}

# Determine which hook to install based on environment
# Windows Git typically expects Unix-style scripts even on Windows
if (Test-Path $preCommitHook) {
    Write-Host "📝 Installing pre-commit hook..." -ForegroundColor Green
    Copy-Item $preCommitHook $installedHook -Force
} else {
    Write-Host "❌ Error: pre-commit hook not found in $hooksDir" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Pre-commit hook installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 What this hook does:" -ForegroundColor Cyan
Write-Host "  • Automatically formats Dart code before commits" -ForegroundColor White
Write-Host "  • Ensures consistent code style across the project" -ForegroundColor White
Write-Host "  • Prevents commits with unformatted Dart code" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Usage:" -ForegroundColor Cyan
Write-Host "  • Just commit as usual: git commit -m 'your message'" -ForegroundColor White
Write-Host "  • The hook will automatically format and re-stage Dart files" -ForegroundColor White
Write-Host "  • If files are formatted, they'll be included in your commit" -ForegroundColor White
Write-Host ""
Write-Host "🔧 To disable temporarily:" -ForegroundColor Cyan
Write-Host "  • Use: git commit --no-verify -m 'your message'" -ForegroundColor White
Write-Host ""
Write-Host "✨ Setup complete! Happy coding!" -ForegroundColor Magenta
