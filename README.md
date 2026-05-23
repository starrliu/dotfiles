# Dotfiles

个人配置文件，使用 [GNU Stow](https://www.gnu.org/software/stow/) 管理。

## 包含内容

- **zsh** - Zsh 配置（补全、键位绑定、alias、prompt 等）
- **tmux** - Tmux 配置（Ctrl+a prefix、vim 风格移动、鼠标支持、resurrect/continuum 持久化）
- **git** - Git 配置

可由 Stow 安装的配置位于 `stow-dotfiles/`：

```text
stow-dotfiles/
  git/.gitconfig
  tmux/.tmux.conf
  zsh/.zshrc
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

安装脚本会安装基础工具、zsh 插件、TPM，并用 Stow 链接 `git`、`tmux`、`zsh` 配置。

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
```

## 卸载

```bash
cd ~/dotfiles/stow-dotfiles
stow -D -t "$HOME" zsh tmux git
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
