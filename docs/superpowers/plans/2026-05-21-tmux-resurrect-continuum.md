# tmux-resurrect / continuum Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add TPM + tmux-resurrect + tmux-continuum to the dotfiles repo so tmux sessions persist and auto-restore across server restarts.

**Architecture:** Append plugin declarations to `tmux/.tmux.conf`. Add two helper functions to `install.sh` (clone TPM; invoke TPM's headless `install_plugins`). `link_dotfiles` must run before `install_tmux_plugins` so `~/.tmux.conf` exists when TPM scans for `@plugin` lines.

**Tech Stack:** bash, tmux, GNU Stow, TPM (`tmux-plugins/tpm`), tmux-resurrect, tmux-continuum.

**Spec:** `docs/superpowers/specs/2026-05-21-tmux-resurrect-continuum-design.md`

---

## File Structure

- Modify: `tmux/.tmux.conf` — append plugin block at end
- Modify: `install.sh` — add `install_tpm` + `install_tmux_plugins` functions; update `main()` ordering and "Next steps" output
- Modify: `README.md` — update tmux feature line; add "Tmux 持久化" section

No new files.

---

### Task 1: Append plugin configuration to tmux.conf

**Files:**
- Modify: `tmux/.tmux.conf` (append at end of file)

- [ ] **Step 1: Append plugin block**

Open `tmux/.tmux.conf` and append the following at the end of the file (after the existing `terminal-overrides` line, with one blank line of separation):

```tmux

# ─── Plugins (TPM) ────────────────────────────────────────────
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# resurrect: 保存 pane 内容 + 指定要恢复的程序
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-processes 'vim nvim tail less man top htop'

# continuum: 自动保存 + 启动时自动恢复
set -g @continuum-save-interval '15'
set -g @continuum-restore 'on'

# 必须在文件最末尾
run '~/.tmux/plugins/tpm/tpm'
```

- [ ] **Step 2: Verify syntax with tmux**

Run: `tmux -f tmux/.tmux.conf -L plan-check new-session -d 'sleep 1' 2>&1; tmux -L plan-check kill-server 2>/dev/null`

Expected: command exits without "unknown command" or "syntax error" output. Warnings about missing `~/.tmux/plugins/tpm/tpm` are expected and OK at this stage (the `run` line will fail silently because TPM isn't installed yet — that's fine, it doesn't break tmux startup).

- [ ] **Step 3: Commit**

```bash
git add tmux/.tmux.conf
git commit -m "tmux: add resurrect/continuum plugin config via TPM"
```

---

### Task 2: Add install_tpm function to install.sh

**Files:**
- Modify: `install.sh` (add function definition)

- [ ] **Step 1: Add the function**

In `install.sh`, add a new function definition after `install_zsh_plugins` and before `link_dotfiles`. Insert this block:

```bash
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
```

Renumber the subsequent comment headers in the file: `4. 使用 Stow` → `5. 使用 Stow`; `5. 设置默认 Shell` → `6. 设置默认 Shell`.

- [ ] **Step 2: Sanity check shell syntax**

Run: `bash -n install.sh`

Expected: no output (syntax OK).

- [ ] **Step 3: Commit**

```bash
git add install.sh
git commit -m "install: add install_tpm to clone TPM into ~/.tmux/plugins/tpm"
```

---

### Task 3: Add install_tmux_plugins function to install.sh

**Files:**
- Modify: `install.sh` (add second function definition)

- [ ] **Step 1: Add the function**

In `install.sh`, add this function definition immediately after `install_tpm()` (before the `5. 使用 Stow` section header):

```bash
# 安装 TPM 列出的插件（resurrect + continuum）
install_tmux_plugins() {
    info "Installing tmux plugins via TPM..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || \
        warn "Plugin install failed; run 'prefix + I' inside tmux to retry"
}
```

- [ ] **Step 2: Sanity check shell syntax**

Run: `bash -n install.sh`

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add install.sh
git commit -m "install: add install_tmux_plugins for headless TPM plugin install"
```

---

### Task 4: Wire new functions into main() with correct ordering

**Files:**
- Modify: `install.sh` (the `main()` function body)

- [ ] **Step 1: Update main() call sequence**

In `install.sh`, find the `main()` function. Replace the existing call sequence:

```bash
    install_packages
    install_conda
    install_zsh_plugins
    link_dotfiles
    set_default_shell
```

with:

```bash
    install_packages
    install_conda
    install_zsh_plugins
    install_tpm
    link_dotfiles
    install_tmux_plugins
    set_default_shell
```

**Why this order:** `install_tmux_plugins` calls TPM's `bin/install_plugins`, which reads `~/.tmux.conf` to discover which plugins to install. That symlink is created by `link_dotfiles` (stow), so `link_dotfiles` MUST run before `install_tmux_plugins`. `install_tpm` can run before or after `link_dotfiles`; we put it before so a TPM clone failure aborts early before stow side-effects.

- [ ] **Step 2: Add post-install hint about existing tmux server**

In `main()`, find the "Next steps" `echo` block. Add after the existing item 3 (the `exec zsh` line):

```bash
    echo ""
    echo "  4. If a tmux server is already running, restart it for plugins to load:"
    echo "     tmux kill-server"
```

- [ ] **Step 3: Sanity check shell syntax**

Run: `bash -n install.sh`

Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add install.sh
git commit -m "install: wire TPM + plugin install into main() with correct ordering"
```

---

### Task 5: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update tmux feature line**

In `README.md`, find the line:

```markdown
- **tmux** - Tmux 配置（Ctrl+a prefix、vim 风格移动、鼠标支持）
```

Replace with:

```markdown
- **tmux** - Tmux 配置（Ctrl+a prefix、vim 风格移动、鼠标支持、resurrect/continuum 持久化）
```

- [ ] **Step 2: Add "Tmux 持久化" section**

In `README.md`, after the "### Zsh 插件" subsection (and before "### 本地配置"), insert:

```markdown
### Tmux 持久化

`install.sh` 会自动安装 TPM 与以下插件：

- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) — 保存/恢复 session、window、pane 布局与 scrollback
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) — 每 15 分钟自动保存；tmux server 启动时自动恢复

快捷键：

- `prefix + Ctrl-s` — 手动保存
- `prefix + Ctrl-r` — 手动恢复

快照位置：`~/.tmux/resurrect/`（`last` 软链指向最新快照）。

会被恢复的进程白名单：`vim nvim tail less man top htop`。其它进程（如 ssh、REPL）恢复后 pane 是干净的 shell。
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document tmux resurrect/continuum setup in README"
```

---

### Task 6: End-to-end verification on this machine

This task runs the actual install steps locally and verifies behavior. Tasks 1–5 are now complete and committed.

**Files:** none (verification only)

- [ ] **Step 1: Install TPM and plugins**

Run from the repo root:

```bash
./install.sh
```

(If you don't want to re-run the whole installer, you can run only the new steps manually:)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || echo "already cloned"
# stow should already have linked ~/.tmux.conf; if not: (cd ~/dotfiles && stow tmux)
~/.tmux/plugins/tpm/bin/install_plugins
```

Expected: output mentions installing `tmux-resurrect` and `tmux-continuum`, ending with a success summary. The directories `~/.tmux/plugins/tmux-resurrect` and `~/.tmux/plugins/tmux-continuum` now exist.

- [ ] **Step 2: Verify directories**

Run: `ls ~/.tmux/plugins/`

Expected: at minimum: `tpm  tmux-resurrect  tmux-continuum`.

- [ ] **Step 3: Restart tmux and verify config loads**

Run:

```bash
tmux kill-server 2>/dev/null
tmux new-session -d -s verify
tmux send-keys -t verify 'echo hello-resurrect-test' Enter
tmux list-sessions
```

Expected: a session named `verify` is listed.

- [ ] **Step 4: Verify plugin keybindings are bound**

Run: `tmux list-keys | grep -E '(resurrect|continuum|C-s|C-r)' | head -20`

Expected: at least two lines mentioning `run-shell` paths under `~/.tmux/plugins/tmux-resurrect/scripts/`, bound to `C-s` (save) and `C-r` (restore).

- [ ] **Step 5: Trigger manual save and inspect snapshot**

Run:

```bash
tmux send-keys -t verify '' ''   # ensure pane is idle
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh
ls -la ~/.tmux/resurrect/
```

Expected: a `last` symlink and one or more `tmux_resurrect_*.txt` files. The `last` link points to the newest one.

- [ ] **Step 6: Test auto-restore across kill-server**

Run:

```bash
tmux kill-server
tmux new-session -d -s probe   # start a fresh server; continuum-restore fires
sleep 2
tmux list-sessions
```

Expected: in addition to `probe`, the previously-saved `verify` session is restored automatically.

- [ ] **Step 7: Cleanup verification sessions**

Run:

```bash
tmux kill-session -t verify 2>/dev/null
tmux kill-session -t probe 2>/dev/null
```

- [ ] **Step 8: No commit needed**

Verification only; no source changes.

---

## Self-Review Notes

- **Spec coverage:** Tasks 1 (tmux.conf), 2–4 (install.sh: install_tpm, install_tmux_plugins, main ordering + tmux kill-server hint), 5 (README) cover all three file changes called out in the spec. Task 6 validates the four spec acceptance criteria (config loads, plugins installed, save/restore round-trips, vim-class processes restored — covered implicitly via keybinding verification + restore round-trip; full vim-restart check is light because it's identical mechanics to scrollback restore).
- **Placeholder scan:** No TBD / TODO / "appropriate handling" phrases. Every code block is the literal text to insert.
- **Ordering invariants:** `link_dotfiles` before `install_tmux_plugins` is documented in Task 4 Step 1 explanation.
- **Type/name consistency:** Function names `install_tpm`, `install_tmux_plugins` used consistently. `~/.tmux/plugins/tpm/bin/install_plugins` path consistent across Task 3 and Task 6.
