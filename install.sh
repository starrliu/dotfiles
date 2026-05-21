#!/bin/bash
# dotfiles 安装脚本

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ═══════════════════════════════════════════
# 1. 安装系统工具
# ═══════════════════════════════════════════
install_packages() {
    info "Installing system packages..."

    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y zsh tmux git stow vim neovim curl wget
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y zsh tmux git stow vim neovim curl wget
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm zsh tmux git stow vim neovim curl wget
    elif command -v brew &> /dev/null; then
        brew install zsh tmux git stow vim neovim curl wget
    else
        warn "Unknown package manager, please install manually: zsh tmux git stow vim neovim"
        return 1
    fi
}

# ═══════════════════════════════════════════
# 2. 安装 Miniconda
# ═══════════════════════════════════════════
install_conda() {
    if command -v conda &> /dev/null; then
        info "Conda already installed, skipping..."
        return 0
    fi

    info "Installing Miniconda..."

    local MINICONDA_URL
    case "$(uname -s)" in
        Linux)  MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" ;;
        Darwin) MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh" ;;
        *)      warn "Unsupported OS for Miniconda"; return 1 ;;
    esac

    local INSTALLER="/tmp/miniconda.sh"
    curl -fsSL "$MINICONDA_URL" -o "$INSTALLER"
    bash "$INSTALLER" -b -p "$HOME/miniconda3"
    rm "$INSTALLER"

    info "Conda installed. Run 'conda init zsh' to initialize."
}

# ═══════════════════════════════════════════
# 3. 安装 Zsh 插件
# ═══════════════════════════════════════════
install_zsh_plugins() {
    info "Installing zsh plugins..."

    local PLUGIN_DIR="$HOME/.zsh/plugins"
    mkdir -p "$PLUGIN_DIR"

    if [[ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
    else
        info "zsh-autosuggestions already installed"
    fi

    if [[ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
    else
        info "zsh-syntax-highlighting already installed"
    fi
}

# ═══════════════════════════════════════════
# 4. 安装 TPM (Tmux Plugin Manager)
# ═══════════════════════════════════════════
install_tpm() {
    info "Installing TPM..."
    local TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$TPM_DIR" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    else
        info "TPM already installed"
    fi
}

# 安装 TPM 列出的插件（resurrect + continuum）
install_tmux_plugins() {
    info "Installing tmux plugins via TPM..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || \
        warn "Plugin install failed; run 'prefix + I' inside tmux to retry"
}

# ═══════════════════════════════════════════
# 5. 使用 Stow 链接 dotfiles
# ═══════════════════════════════════════════
link_dotfiles() {
    info "Linking dotfiles with stow..."

    cd "$DOTFILES_DIR"
    stow -v zsh
    stow -v tmux
    stow -v git
}

# ═══════════════════════════════════════════
# 6. 设置默认 Shell
# ═══════════════════════════════════════════
set_default_shell() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Setting zsh as default shell..."
        chsh -s "$(which zsh)"
    else
        info "Zsh is already the default shell"
    fi
}

# ═══════════════════════════════════════════
# Main
# ═══════════════════════════════════════════
main() {
    echo "╔════════════════════════════════════════╗"
    echo "║        Dotfiles Install Script         ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    install_packages
    install_conda
    install_zsh_plugins
    link_dotfiles
    set_default_shell

    echo ""
    info "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Configure git user info:"
    echo "     git config --global user.name 'Your Name'"
    echo "     git config --global user.email 'your@email.com'"
    echo ""
    echo "  2. Initialize conda for zsh:"
    echo "     ~/miniconda3/bin/conda init zsh"
    echo ""
    echo "  3. Restart your shell or run: exec zsh"
}

main "$@"
