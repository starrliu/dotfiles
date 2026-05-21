# Dotfiles

个人配置文件，使用 [GNU Stow](https://www.gnu.org/software/stow/) 管理。

## 包含内容

- **zsh** - Zsh 配置（补全、键位绑定、alias、prompt 等）
- **tmux** - Tmux 配置（Ctrl+a prefix、vim 风格移动、鼠标支持、resurrect/continuum 持久化）
- **git** - Git 配置

## 安装

```bash
# 克隆到 home 目录
git clone <repo-url> ~/dotfiles
cd ~/dotfiles

# 安装 stow（如果没有）
sudo apt install stow  # Debian/Ubuntu
# brew install stow    # macOS

# 运行安装脚本
./install.sh
```

## 手动安装单个模块

```bash
cd ~/dotfiles
stow zsh    # 只安装 zsh 配置
stow tmux   # 只安装 tmux 配置
stow git    # 只安装 git 配置
```

## 卸载

```bash
cd ~/dotfiles
stow -D zsh tmux git
```

## 安装后配置

### Git 用户信息

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### Zsh 插件

需要手动安装以下插件：

```bash
mkdir -p ~/.zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
```

### Tmux 持久化

`install.sh` 会自动安装 TPM 与以下插件：

- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) — 保存/恢复 session、window、pane 布局与 scrollback
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) — 每 15 分钟自动保存；tmux server 启动时自动恢复

快捷键：

- `prefix + Ctrl-s` — 手动保存
- `prefix + Ctrl-r` — 手动恢复

快照位置：`${XDG_DATA_HOME:-~/.local/share}/tmux/resurrect/`（`last` 软链指向最新快照）。

会被恢复的进程白名单：`vim nvim tail less man top htop`。其它进程（如 ssh、REPL）恢复后 pane 是干净的 shell。

### 本地配置

主机特定配置（conda、nvm、fzf 等）放在 `~/.zshrc.local`，该文件不纳入版本控制。

示例：

```bash
# ~/.zshrc.local

# conda
__conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
fi
unset __conda_setup

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
```
