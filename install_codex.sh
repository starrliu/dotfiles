#!/usr/bin/env bash
# Install Codex CLI with the optional ghc-api Copilot proxy setup.
set -euo pipefail

run_as_root() {
    if [[ "$EUID" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        printf 'Installing system prerequisites requires sudo or root.\n' >&2
        return 1
    fi
}

install_prerequisites() {
    local packages=() tool
    for tool in curl pipx; do
        command -v "$tool" >/dev/null 2>&1 || packages+=("$tool")
    done
    [[ ${#packages[@]} -gt 0 ]] || return 0

    printf 'Installing prerequisites: %s\n' "${packages[*]}"
    if command -v brew >/dev/null 2>&1; then
        brew install "${packages[@]}"
    elif command -v apt-get >/dev/null 2>&1; then
        run_as_root apt-get update
        run_as_root apt-get install -y "${packages[@]}" ca-certificates
    elif command -v dnf >/dev/null 2>&1; then
        run_as_root dnf install -y "${packages[@]}" ca-certificates
    elif command -v pacman >/dev/null 2>&1; then
        # Arch names the pipx package python-pipx.
        for tool in "${!packages[@]}"; do
            [[ "${packages[$tool]}" != pipx ]] || packages[$tool]=python-pipx
        done
        run_as_root pacman -S --needed --noconfirm "${packages[@]}" ca-certificates
    else
        printf 'Install %s with your package manager, then rerun. On macOS, install Homebrew first.\n' "${packages[*]}" >&2
        return 1
    fi
}

node_is_ready() {
    command -v node >/dev/null 2>&1 &&
        command -v npm >/dev/null 2>&1 &&
        node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 22 ? 0 : 1)'
}

ensure_node() {
    node_is_ready && return 0

    # Non-interactive bash does not normally load nvm from shell startup files.
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
        printf 'Installing nvm to manage Node.js in your user account...\n'
        local installer
        installer="$(mktemp)"
        if ! curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh -o "$installer"; then
            rm -f "$installer"
            return 1
        fi
        if ! METHOD=script bash "$installer"; then
            rm -f "$installer"
            return 1
        fi
        rm -f "$installer"
    fi
    source "$NVM_DIR/nvm.sh"
    node_is_ready && return 0
    nvm install 22
    nvm use 22
    nvm alias default 22
    node_is_ready
}

write_codex_config() {
    local config_file="$1"
    if [[ -e "$config_file" || -L "$config_file" ]]; then
        printf 'Keeping existing config: %s\n' "$config_file"
        return
    fi
    mkdir -p "$(dirname "$config_file")"
    # noclobber also prevents overwriting a config created concurrently.
    (
        set -o noclobber
        cat > "$config_file" <<'CONFIG'
model = "gpt-5.5"
model_provider = "ghc-api"
model_reasoning_effort = "high"

[model_providers.ghc-api]
name = "ghc-api"
base_url = "http://localhost:8313/v1"
wire_api = "responses"
CONFIG
    )
    printf 'Created config: %s\n' "$config_file"
}

main() {
    if [[ "${1:-}" == "--help" ]]; then
        cat <<'HELP'
Usage: bash install_codex.sh

Install Codex CLI and authenticate ghc-api with GitHub Copilot.
Installs missing curl/pipx via apt, dnf, pacman, or Homebrew (sudo may be needed).
Loads existing nvm or installs it with Node.js 22 when Node/npm is missing or old.
Requires a GitHub Copilot subscription and network access.
Run this script as your normal user. Authentication is interactive.
An existing $CODEX_HOME/config.toml (default ~/.codex/config.toml) is preserved.
Only a missing config is initialized for ghc-api on localhost:8313.
HELP
        return
    fi
    if [[ $# -ne 0 ]]; then
        printf 'Unknown argument. Use --help.\n' >&2
        return 1
    fi
    export PATH="$HOME/.local/bin:$PATH"
    install_prerequisites
    ensure_node
    pipx ensurepath --force

    pipx run ghc-api --help >/dev/null
    pipx run ghc-api --github-device-login
    npm install -g --prefix "$HOME/.local" @openai/codex
    write_codex_config "${CODEX_HOME:-$HOME/.codex}/config.toml"
    codex --version

    printf '\nStart the proxy: pipx run ghc-api -p 8313\n'
    printf 'Then run: codex\n'
    printf 'If a config was preserved, review its provider and endpoint before using the proxy.\n'
    printf 'Open a new terminal to load any PATH and nvm startup changes.\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
