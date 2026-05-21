# tmux-resurrect / continuum 集成方案

日期：2026-05-21
状态：待实施

## 背景

`~/dotfiles` 通过 GNU Stow 管理 zsh / tmux / git 配置，由 `install.sh` 完成系统包安装、conda、zsh 插件、stow 链接等步骤。当前 tmux 配置（`tmux/.tmux.conf`）没有插件机制，无法在 tmux server 重启或机器重启后恢复 session/window/pane 状态。

本方案引入 [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) + [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)，并通过 [TPM](https://github.com/tmux-plugins/tpm) 管理插件，使 tmux 状态可持久化和自动恢复。

## 决策汇总

| 项 | 选择 | 备注 |
|---|---|---|
| 插件管理器 | TPM | 与现有 zsh 插件 `git clone` 风格一致；后续扩展插件零成本 |
| 自动恢复 | `@continuum-restore 'on'` | tmux server 启动时自动恢复 |
| 自动保存间隔 | 15 分钟（默认） | 平衡 IO 与丢失窗口 |
| 恢复进程白名单 | `vim nvim tail less man top htop` | 只读 / 安全重入；不含 ssh、REPL |
| pane 内容快照 | `@resurrect-capture-pane-contents 'on'` | 保留 scrollback 上下文；与现有 `history-limit 50000` 匹配 |

已知权衡（用户接受）：
- 自动恢复会"复活"两次快照之间手动删除的 window/pane
- 长期使用后启动时可能带回偶尔用过的旧 session

## 文件改动

### 1. `tmux/.tmux.conf`

在现有内容末尾追加：

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

### 2. `install.sh`

新增两个函数：

```bash
# ═══════════════════════════════════════════
# 安装 TPM (Tmux Plugin Manager)
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
```

`main()` 调用顺序调整为：

```bash
install_packages
install_conda
install_zsh_plugins
install_tpm           # 新增
link_dotfiles         # stow 必须先于 install_tmux_plugins
install_tmux_plugins  # 新增；依赖 ~/.tmux.conf 已链接
set_default_shell
```

**关键约束**：`install_tmux_plugins` 必须在 `link_dotfiles` 之后，因为 `tpm/bin/install_plugins` 会读取 `~/.tmux.conf` 中的 `@plugin` 列表。

`main()` 末尾的 "Next steps" 提示中追加一条：

> 4. 如果当前已有 tmux server 在运行：`tmux kill-server`，下次启动后插件配置才生效。

### 3. `README.md`

- "包含内容" 的 tmux 项更新为：`Tmux 配置（Ctrl+a prefix、vim 风格移动、鼠标支持、resurrect/continuum 持久化）`
- 新增章节 "Tmux 持久化"：
  - 说明插件已通过 `install.sh` 自动安装
  - 列出快捷键：`prefix + Ctrl-s`（手动保存）、`prefix + Ctrl-r`（手动恢复）
  - 说明自动保存间隔 15 分钟、启动时自动恢复
  - 提示快照位置：`~/.tmux/resurrect/`

## 行为说明

- **save 触发时机**：每 15 分钟一次（continuum 定时器） + 用户手动 `prefix + Ctrl-s`
- **restore 触发时机**：tmux server 启动时（continuum 自动） + 用户手动 `prefix + Ctrl-r`
- **快照路径**：`~/.tmux/resurrect/last` 软链指向最新快照；历史快照保留在同目录
- **恢复内容**：所有 session、window 名称、pane 布局、pane 工作目录、pane scrollback 内容，以及白名单中正在运行的进程

## 验收标准

1. 全新机器跑完 `./install.sh`，重开终端，启动 `tmux`：prefix 仍为 `C-a`，鼠标可用，状态栏正常
2. 在 tmux 内 `prefix + I` 显示 "Already installed"（TPM + 插件已就位）
3. 创建 2 个 window 各跑一些命令产生输出，执行 `prefix + Ctrl-s`，然后 `tmux kill-server`，再重开 tmux：自动恢复 2 个 window，pane 内容（scrollback）可见
4. 在某 pane 内打开 `vim`，重复 kill-server + 重连：vim 进程被重新启动（pane 内有 vim 在跑，不要求恢复编辑会话）

## 范围外（未来可考虑）

- 跨机器同步快照（syncthing / rsync `~/.tmux/resurrect/`）
- vim/nvim session 集成（`@resurrect-strategy-vim 'session'`）
- 其他 tmux 插件（tmux-yank、tmux-sensible 等）
