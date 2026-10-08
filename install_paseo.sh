#!/usr/bin/env bash
# Install the headless Paseo daemon for access through SSH on Linux.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

show_help() {
    cat <<'HELP'
Usage: ./install_paseo.sh [--help]

Install Paseo in ~/.local and enable a systemd user service on Linux.
Requires Node.js >= 22, npm, and a working systemd user manager.
Loads an existing ~/.nvm installation if Node/npm is missing or too old.
Run as your normal user, without sudo.

PASEO_VERSION selects the npm version (default: 0.11.1).
Existing ~/.paseo/config.json is preserved. A new config listens only on
127.0.0.1:6767 with relay disabled, for Windows Desktop's Remote SSH transport.
Changed service files are backed up before replacement. An active daemon is
not restarted automatically; restart it when convenient to apply updates.
HELP
}

node_is_ready() {
    command -v node >/dev/null 2>&1 &&
        command -v npm >/dev/null 2>&1 &&
        node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 22 ? 0 : 1)'
}

ensure_node() {
    if ! node_is_ready && [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
        # Non-interactive Bash does not normally initialize nvm.
        source "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    fi
    node_is_ready || die 'Install/activate Node.js >= 22 and npm, then rerun (for nvm: nvm install 22).'
}

initialize_config() {
    local paseo_home="$1"
    mkdir -p "$paseo_home"
    node - "$SCRIPT_DIR/examples/paseo/config.json" "$paseo_home/config.json" <<'JS'
const fs = require('node:fs');
const [source, target] = process.argv.slice(2);
try {
    fs.copyFileSync(source, target, fs.constants.COPYFILE_EXCL);
    fs.chmodSync(target, 0o600);
    console.log(`[INFO] Created config: ${target}`);
} catch (error) {
    if (error.code !== 'EEXIST') throw error;
    console.log(`[INFO] Keeping existing config: ${target}`);
}
JS
}

render_service() {
    local node_bin="$1" paseo_bin="$2" paseo_home="$3"
    node - "$SCRIPT_DIR/examples/paseo/paseo.service.in" \
        "$node_bin" "$paseo_bin" "$paseo_home" "$PATH" "${SHELL:-/bin/bash}" <<'JS'
const fs = require('node:fs');
const [template, node, paseo, home, path, shell] = process.argv.slice(2);
// systemd has its own quoting, specifiers, and ExecStart variable expansion.
function quote(value, exec = false) {
    if (/[\r\n\0]/.test(value)) throw new Error('Service values must be single-line strings');
    let escaped = value.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/%/g, '%%');
    if (exec) escaped = escaped.replace(/\$/g, '$$$$');
    return `"${escaped}"`;
}
const values = {
    NODE: quote(node, true),
    PASEO: quote(paseo, true),
    PASEO_HOME: quote(home, true),
    PATH: quote(`PATH=${path}`),
    SHELL: quote(`SHELL=${shell}`),
};
process.stdout.write(fs.readFileSync(template, 'utf8').replace(/@(\w+)@/g, (_, key) => values[key]));
JS
}

install_service() {
    local node_bin="$1" paseo_bin="$2" paseo_home="$3"
    local service_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    local service_file="$service_dir/paseo.service" temporary backup
    mkdir -p "$service_dir"
    temporary="$(mktemp "$service_dir/.paseo.service.XXXXXX")"
    if ! render_service "$node_bin" "$paseo_bin" "$paseo_home" > "$temporary"; then
        rm -f "$temporary"
        return 1
    fi
    if cmp -s "$temporary" "$service_file"; then
        rm -f "$temporary"
        info "Service unchanged: $service_file"
    else
        if [[ -e "$service_file" || -L "$service_file" ]]; then
            backup="$(mktemp "$service_file.backup.XXXXXX")"
            cp -L -- "$service_file" "$backup"
            info "Previous service backed up to: $backup"
        fi
        mv -f -- "$temporary" "$service_file"
        info "Installed service: $service_file"
    fi
    systemctl --user daemon-reload
    systemctl --user enable paseo.service
}

start_service() {
    local paseo_bin="$1" paseo_home="$2" attempt
    if systemctl --user is-active --quiet paseo.service; then
        info 'Paseo is already active; keeping the running daemon.'
        info 'To apply a CLI, Node path, or service update: systemctl --user restart paseo'
        return
    fi
    if "$paseo_bin" daemon status --home "$paseo_home" --json | \
        node -e 'let s=""; process.stdin.on("data", c => s += c); process.stdin.on("end", () => { try { process.exit(JSON.parse(s).localDaemon === "running" ? 0 : 1); } catch { process.exit(1); } });'; then
        warn 'A standalone Paseo daemon is already running; leaving it in place.'
        warn 'When ready, run: paseo daemon stop --home ~/.paseo && systemctl --user start paseo'
        return
    fi
    systemctl --user start paseo.service
    for attempt in {1..30}; do
        if "$paseo_bin" daemon status --home "$paseo_home" --json | \
            node -e 'let s=""; process.stdin.on("data", c => s += c); process.stdin.on("end", () => { try { process.exit(JSON.parse(s).connectedDaemon === "reachable" ? 0 : 1); } catch { process.exit(1); } });'; then
            info 'Paseo daemon is reachable.'
            return
        fi
        sleep 1
    done
    die 'Daemon is not ready. Inspect: journalctl --user -u paseo -n 50 --no-pager'
}

main() {
    if [[ $# -eq 1 && "$1" == --help ]]; then show_help; return; fi
    [[ $# -eq 0 ]] || die 'Unknown argument. Use --help.'
    [[ "$(uname -s)" == Linux ]] || die 'This installer requires Linux with systemd.'
    [[ "$EUID" -ne 0 ]] || die 'Run this script as your normal user, without sudo.'
    command -v systemctl >/dev/null 2>&1 || die 'systemctl is required.'
    systemctl --user show-environment >/dev/null || die 'No systemd user manager. Run from a normal SSH login on the target host.'
    ensure_node
    umask 077

    local node_bin paseo_bin="$HOME/.local/bin/paseo" paseo_home="$HOME/.paseo"
    local version="${PASEO_VERSION:-0.11.1}" current_version
    node_bin="$(node -p 'process.execPath')"
    export PATH="$HOME/.local/bin:$(dirname "$node_bin"):$PATH"
    current_version="$("$paseo_bin" --version 2>/dev/null || true)"
    if [[ "$current_version" == "$version" ]]; then
        info "Paseo $version is already installed in ~/.local."
    else
        npm install --global --prefix "$HOME/.local" "@getpaseo/cli@$version"
    fi
    "$paseo_bin" --version
    initialize_config "$paseo_home"
    install_service "$node_bin" "$paseo_bin" "$paseo_home"

    if ! loginctl enable-linger "$(id -un)" --no-ask-password; then
        warn "Could not enable startup without a login. Run: sudo loginctl enable-linger $(id -un)"
    fi
    start_service "$paseo_bin" "$paseo_home"
    info 'Keep ~/.local/bin on your shell PATH. See docs/paseo.md for Windows SSH setup and provider diagnostics.'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
