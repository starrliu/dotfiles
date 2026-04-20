#!/bin/bash
# dotfiles 安装脚本 - 使用 GNU Stow

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# 检查 stow 是否安装
if ! command -v stow &> /dev/null; then
    echo "Error: stow is not installed"
    echo "Install with: sudo apt install stow"
    exit 1
fi

cd "$DOTFILES_DIR"

# 使用 stow 创建 symlink
echo "Installing dotfiles with stow..."
stow -v zsh
stow -v tmux
stow -v git

echo "Done!"
echo ""
echo "Note: You may want to configure git user info:"
echo "  git config --global user.name 'Your Name'"
echo "  git config --global user.email 'your@email.com'"
