#!/usr/bin/env bash
# dotfiles installer for macOS.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$SCRIPT_DIR/stow-dotfiles"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }

show_help() {
    cat <<EOF
Usage: $0 [options]

Install dotfiles on macOS. Existing dotfiles are not merged or backed up
automatically; resolve stow conflicts manually before rerunning.

Options:
  --help            Show this help message
  --install-conda   Install Miniconda if conda is not already available
  --skip-packages   Skip Homebrew package installation
EOF
}

INSTALL_CONDA=false
SKIP_PACKAGES=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) show_help; exit 0 ;;
        --install-conda) INSTALL_CONDA=true ;;
        --skip-packages) SKIP_PACKAGES=true ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
    shift
done

ensure_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        return
    fi

    info "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

install_packages() {
    ensure_homebrew
    info "Installing Homebrew packages..."
    brew update
    brew install zsh tmux git stow vim neovim curl wget
}

install_conda() {
    if command -v conda >/dev/null 2>&1; then
        info "Conda already installed; skipping."
        return
    fi

    local arch
    case "$(uname -m)" in
        arm64) arch="arm64" ;;
        x86_64) arch="x86_64" ;;
        *) warn "Unsupported macOS architecture for Miniconda: $(uname -m)"; return 1 ;;
    esac

    info "Installing Miniconda..."
    local installer="/tmp/miniconda.sh"
    curl -fsSL "https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-${arch}.sh" -o "$installer"
    bash "$installer" -b -p "$HOME/miniconda3"
    rm "$installer"
    info "Conda installed. Run '~/miniconda3/bin/conda init zsh' if needed."
}

install_zsh_plugins() {
    info "Installing zsh plugins..."
    local plugin_dir="$HOME/.zsh/plugins"
    mkdir -p "$plugin_dir"

    if [[ ! -d "$plugin_dir/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions"
    fi

    if [[ ! -d "$plugin_dir/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir/zsh-syntax-highlighting"
    fi
}

install_tpm() {
    info "Installing TPM..."
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$tpm_dir" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi
}

link_dotfiles() {
    info "Linking dotfiles with stow..."
    cd "$STOW_DIR"
    stow -t "$HOME" -v git tmux zsh
}

install_tmux_plugins() {
    info "Installing tmux plugins via TPM..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || \
        warn "Plugin install failed; run 'prefix + I' inside tmux to retry."
}

main() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "This script is intended for macOS. Use ./install_linux.sh on Linux."
        exit 1
    fi

    [[ "$SKIP_PACKAGES" == true ]] || install_packages
    [[ "$INSTALL_CONDA" == false ]] || install_conda
    install_zsh_plugins
    install_tpm
    link_dotfiles
    install_tmux_plugins

    info "Installation complete. Restart your shell or run: exec zsh"
}

main "$@"
