#!/bin/bash

# Pre-commit setup script for EBK Flutter App
# This script installs and configures pre-commit hooks

set -e

echo "🔧 Setting up pre-commit hooks for EBK Flutter App..."

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "❌ pre-commit is not installed. Installing..."

    # Try to install via pip
    if command -v pip3 &> /dev/null; then
        pip3 install pre-commit
    elif command -v pip &> /dev/null; then
        pip install pre-commit
    elif command -v brew &> /dev/null; then
        # macOS with Homebrew
        brew install pre-commit
    else
        echo "❌ Could not install pre-commit automatically."
        echo "Please install pre-commit manually:"
        echo "  - pip install pre-commit"
        echo "  - or brew install pre-commit (macOS)"
        echo "  - or visit https://pre-commit.com/#installation"
        exit 1
    fi
fi

echo "✅ pre-commit is installed"

# Install the git hook scripts
echo "🔗 Installing pre-commit git hooks..."
pre-commit install

# Optionally run hooks on all files
read -p "🤔 Do you want to run pre-commit on all existing files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Running pre-commit on all files..."
    pre-commit run --all-files
fi

echo "✅ Pre-commit setup complete!"
echo ""
echo "📋 Available commands:"
echo "  - pre-commit run --all-files    # Run on all files"
echo "  - pre-commit run dart-format    # Run only dart format"
echo "  - pre-commit run dart-test      # Run tests (manual stage)"
echo ""
echo "🎯 Hooks will now run automatically before each commit!"
echo ""
echo "🤖 CI/CD Auto-fixes:"
echo "  - Main branch: Formatting fixes are auto-committed"
echo "  - Pull requests: Formatting suggestions are provided in comments"
echo "  - Nightly builds: Auto-format and commit any style drift"
