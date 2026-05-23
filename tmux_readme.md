# Tmux 配置说明

配置文件位置：`stow-dotfiles/tmux/.tmux.conf`

安装后链接到：`~/.tmux.conf`

## Prefix

默认 prefix 从 `Ctrl+b` 改为：

```text
Ctrl+a
```

`Ctrl+b` 已解绑。

如果需要向 tmux 内部程序发送 prefix，使用：

```text
Ctrl+a Ctrl+a
```

## 常用快捷键

以下快捷键都需要先按 prefix，也就是 `Ctrl+a`。

| 快捷键 | 行为 |
| --- | --- |
| `v` | 左右分屏，新 pane 继承当前目录 |
| `-` | 上下分屏，新 pane 继承当前目录 |
| `h` | 切换到左侧 pane |
| `j` | 切换到下方 pane |
| `k` | 切换到上方 pane |
| `l` | 切换到右侧 pane |
| `Ctrl-s` | 使用 tmux-resurrect 手动保存会话 |
| `Ctrl-r` | 使用 tmux-resurrect 手动恢复会话 |

## Pane 和窗口行为

- 鼠标支持已开启，可以点击切换 pane 或拖动边界调整大小。
- window 编号从 `1` 开始。
- scrollback 历史行数设置为 `50000`。
- 新分屏会继承当前 pane 的工作目录。

## 状态栏

右侧状态栏显示：

- 当前时间：`%H:%M`
- 当前日期：`%d-%b`
- 如果当前 window 处于 zoom 状态，会显示放大镜标记。

## 颜色和终端能力

配置项：

```tmux
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"
```

效果：

- 启用 256 色支持
- 对支持的终端启用 true color

## 插件

使用 TPM 管理插件：

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-resurrect`
- `tmux-plugins/tmux-continuum`

TPM 路径：

```bash
~/.tmux/plugins/tpm
```

## 会话保存和恢复

`tmux-resurrect` 配置：

- 保存 pane 内容：开启
- 恢复进程白名单：
  - `vim`
  - `nvim`
  - `tail`
  - `less`
  - `man`
  - `top`
  - `htop`

`tmux-continuum` 配置：

- 每 15 分钟自动保存
- tmux server 启动时自动恢复

快捷键：

| 快捷键 | 行为 |
| --- | --- |
| `Ctrl+a Ctrl-s` | 手动保存 |
| `Ctrl+a Ctrl-r` | 手动恢复 |

快照位置：

```bash
${XDG_DATA_HOME:-~/.local/share}/tmux/resurrect/
```

其中 `last` 软链接指向最新快照。

## 重新加载配置

当前配置没有自定义 reload 快捷键。可在 tmux 命令行中执行：

```tmux
source-file ~/.tmux.conf
```

进入 tmux 命令行：

```text
Ctrl+a :
```
