# Dotfiles

个人配置文件，使用 [GNU Stow](https://www.gnu.org/software/stow/) 管理。

## 包含内容

- **zsh** - Zsh 配置（补全、键位绑定、alias、prompt 等）
- **tmux** - Tmux 配置（Ctrl+a prefix、vim 风格移动、鼠标支持、resurrect/continuum 持久化）
- **git** - Git 配置
- **claude** - Claude Code 配置（settings.json、自定义 skills）
- **agents** - Codex 可发现的共享技能，安装到 `~/.agents/skills/`

可由 Stow 安装的配置位于 `stow-dotfiles/`：

```text
stow-dotfiles/
  git/.gitconfig
  tmux/.tmux.conf
  zsh/.zshrc
  claude/.claude/settings.json
  claude/.claude/skills/
  agents/.agents/skills/
```

## 安装

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles

# macOS
./install_macos.sh

# Linux
./install_linux.sh
```

安装脚本会安装基础工具、zsh 插件、TPM，并用 Stow 链接 `git`、`tmux`、`zsh` 配置及 `agents` 共享技能。

Miniconda 默认不安装。如需安装：

```bash
./install_macos.sh --install-conda
./install_linux.sh --install-conda
```

如果系统工具已经准备好，可以跳过包安装：

```bash
./install_macos.sh --skip-packages
./install_linux.sh --skip-packages
```

## 已有配置的机器

脚本不会自动合并、覆盖或备份已有配置。若已经存在以下文件，`stow` 会报冲突并停止：

```text
~/.zshrc
~/.tmux.conf
~/.gitconfig
~/.claude/settings.json
~/.claude/skills/
~/.agents/skills/
```

请先手动比较并合并：

```bash
diff -u ~/.zshrc stow-dotfiles/zsh/.zshrc
diff -u ~/.tmux.conf stow-dotfiles/tmux/.tmux.conf
diff -u ~/.gitconfig stow-dotfiles/git/.gitconfig
```

如果决定完全使用本仓库配置，可以自行备份旧文件后重新运行安装脚本：

```bash
mkdir -p ~/.dotfiles-backup
mv ~/.zshrc ~/.dotfiles-backup/ 2>/dev/null || true
mv ~/.tmux.conf ~/.dotfiles-backup/ 2>/dev/null || true
mv ~/.gitconfig ~/.dotfiles-backup/ 2>/dev/null || true
```

## 手动安装单个模块

```bash
cd ~/dotfiles/stow-dotfiles
stow -t "$HOME" zsh    # 只安装 zsh 配置
stow -t "$HOME" tmux   # 只安装 tmux 配置
stow -t "$HOME" git    # 只安装 git 配置
stow -t "$HOME" claude # 只安装 Claude Code 配置
stow -t "$HOME" agents # 只安装共享技能（~/.agents/skills/）
```

`agents` 包使用 `.agents`（复数）目录，供 Codex 自动发现技能。
旧版的 `agent/.agent` 已改名为 `agents/.agents`。已有机器升级时，
先移除指向旧目录的 `~/.agent` 符号链接，以及
`~/.agents/skills/` 内指向 `~/.agent/skills/` 的旧符号链接，再运行上述
`stow -t "$HOME" agents`。只移除符号链接，保留实际目录和自行添加的技能。

## 卸载

```bash
cd ~/dotfiles/stow-dotfiles
stow -D -t "$HOME" zsh tmux git claude agents
```

## 安装后配置

### Git 用户信息

`stow-dotfiles/git/.gitconfig` 包含个人 Git 用户信息。安装前请按需要修改：

```bash
git config --file stow-dotfiles/git/.gitconfig user.name "Your Name"
git config --file stow-dotfiles/git/.gitconfig user.email "your@email.com"
```

### Zsh 插件

安装脚本会自动安装以下插件：

```bash
~/.zsh/plugins/zsh-autosuggestions
~/.zsh/plugins/zsh-syntax-highlighting
```

### Tmux 持久化

安装脚本会自动安装 TPM 与以下插件：

- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) - 保存/恢复 session、window、pane 布局与 scrollback
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) - 每 15 分钟自动保存；tmux server 启动时自动恢复

快捷键：

- `prefix + Ctrl-s` - 手动保存
- `prefix + Ctrl-r` - 手动恢复

快照位置：`${XDG_DATA_HOME:-~/.local/share}/tmux/resurrect/`（`last` 软链指向最新快照）。

会被恢复的进程白名单：`vim nvim tail less man top htop`。其它进程（如 ssh、REPL）恢复后 pane 是干净的 shell。

### 本地配置

主机特定配置（conda、nvm、fzf 等）放在 `~/.zshrc.local`，该文件不纳入 Stow 管理。

示例文件位于：

```bash
examples/.zshrc.local
```

### Claude Code

`stow-dotfiles/claude/` 包含 Claude Code 的基础配置：

- `settings.json` - 通用设置（插件、模式、环境变量默认值）
- `skills/` - 自定义 skills（amlt-cli、amlt-e2e）

机器特定配置（如 `ANTHROPIC_MODEL`、`ANTHROPIC_BASE_URL`）通过 `~/.claude/settings.local.json` 覆盖，不纳入 Stow。

**注意**：若已运行过 Claude Code，`~/.claude/settings.json` 和 `~/.claude/skills/` 可能已存在。Stow 前需先备份：

```bash
mkdir -p ~/.claude-backup
mv ~/.claude/settings.json ~/.claude-backup/ 2>/dev/null || true
mv ~/.claude/skills ~/.claude-backup/ 2>/dev/null || true
```

通知 hooks 仅在 `~/.claude/hooks/notify.sh` 存在且可执行时调用它；该脚本和通知凭据需在本机单独配置。

#### 飞书通知

将 [`setup_claude_feishu_notify.md`](setup_claude_feishu_notify.md) 的内容贴给 Claude Code，它会自动完成通知插件的安装和飞书 webhook 配置。


### 共享 AMLT 技能

`agents` 包包含 `amlt-cli`（命令参考）、`amlt-e2e`（任务提交、监控与恢复流程）
和 Kubernetes 技能。安装后可从 `~/.agents/skills/` 发现它们。
Claude 的 AMLT 技能仍保留在 `~/.claude/skills/`；两处是独立副本，修改通用内容时应同步更新。

机器专属的 AMLT 环境记录不纳入版本管理。需要时，在安装对应包后运行：

```bash
test -e ~/.agents/skills/amlt-e2e/my-env.md || \
  cp ~/.agents/skills/amlt-e2e/my-env.example.md ~/.agents/skills/amlt-e2e/my-env.md
# Claude 用户可在 ~/.claude/skills/amlt-e2e/ 下做相同操作。
```

仅在 `my-env.md` 不存在时复制模板，避免覆盖已有记录。
旧版已跟踪的 Claude `my-env.md` 现已移出版本管理；升级前请将自己的文件备份到仓库外，
升级完成后放回原位置。此变更不会移除 Git 历史中的旧版本。

### Codex CLI（ghc-api 代理）

`bash install_codex.sh` 安装 Codex CLI，并通过交互式 GitHub 登录配置 ghc-api
（将 GitHub Copilot 请求转为本地 API 的代理）。运行前需安装 Node.js 22 或更高版本、
`npm` 和 `pipx`，并拥有 GitHub Copilot 订阅。

脚本保留已有的 `${CODEX_HOME:-$HOME/.codex}/config.toml`；仅在文件不存在时创建配置，
使用 `ghc-api` provider、`http://localhost:8313/v1` 和 `gpt-5.5`。
代理实际提供的模型取决于账号与服务，请按需调整。脚本不默认关闭审批或沙箱。

安装后先运行 `pipx run ghc-api -p 8313`，再在另一个终端运行 `codex`。
若保留了旧配置，请自行核对模型、provider 和代理地址。
