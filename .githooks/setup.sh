#!/bin/bash
# Setup script for git hooks
# This script installs the pre-commit hook and makes it executable

echo "🔧 Setting up git hooks for CanBussy UI..."

# Get the repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel)

if [ -z "$REPO_ROOT" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Define hook paths
HOOKS_DIR="$REPO_ROOT/.githooks"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"
INSTALLED_HOOK="$GIT_HOOKS_DIR/pre-commit"

# Check if our hooks directory exists
if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ Error: .githooks directory not found"
    echo "Please ensure you're in the CanBussy UI project directory"
    exit 1
fi

# Check if pre-commit hook exists
if [ ! -f "$PRE_COMMIT_HOOK" ]; then
    echo "❌ Error: pre-commit hook not found in $HOOKS_DIR"
    exit 1
fi

# Create .git/hooks directory if it doesn't exist
mkdir -p "$GIT_HOOKS_DIR"

# Copy the pre-commit hook
echo "📝 Installing pre-commit hook..."
cp "$PRE_COMMIT_HOOK" "$INSTALLED_HOOK"

# Make the hook executable (Unix/Mac/WSL)
chmod +x "$INSTALLED_HOOK"

echo "✅ Pre-commit hook installed successfully!"
echo ""
echo "🎯 What this hook does:"
echo "  • Automatically formats Dart code before commits"
echo "  • Ensures consistent code style across the project"  
echo "  • Prevents commits with unformatted Dart code"
echo ""
echo "🚀 Usage:"
echo "  • Just commit as usual: git commit -m 'your message'"
echo "  • The hook will automatically format and re-stage Dart files"
echo "  • If files are formatted, they'll be included in your commit"
echo ""
echo "🔧 To disable temporarily:"
echo "  • Use: git commit --no-verify -m 'your message'"
echo ""
echo "✨ Setup complete! Happy coding!"
