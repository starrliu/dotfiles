#!/usr/bin/env bash
# Install Codex CLI with the optional ghc-api Copilot proxy setup.
set -euo pipefail

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
Requires Node.js >= 22, npm, pipx, and a GitHub Copilot subscription.
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
    local tool
    for tool in node npm pipx; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            printf 'Missing prerequisite: %s. Install it before rerunning.\n' "$tool" >&2
            return 1
        fi
    done
    node -e 'if (Number(process.versions.node.split(".")[0]) < 22) { console.error("Node.js >= 22 is required"); process.exit(1); }'

    pipx run ghc-api --help >/dev/null
    pipx run ghc-api --github-device-login
    npm install -g @openai/codex
    write_codex_config "${CODEX_HOME:-$HOME/.codex}/config.toml"
    codex --version

    printf '\nStart the proxy: pipx run ghc-api -p 8313\n'
    printf 'Then run: codex\n'
    printf 'If a config was preserved, review its provider and endpoint before using the proxy.\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
