#!/bin/bash

# Pre-commit setup script for EBK Flutter App
# This script installs and configures pre-commit hooks

set -e

echo "🔧 Setting up pre-commit hooks for EBK Flutter App..."

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "❌ pre-commit is not installed."

    echo "Please install pre-commit:"
    echo "  - pip install pre-commit"
    echo "  - or brew install pre-commit (macOS)"
    echo "  - or visit https://pre-commit.com/#installation"
    exit 1
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
echo "🚀 Happy coding with EBK Flutter App!"
