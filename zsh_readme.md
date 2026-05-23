# Zsh 配置说明

配置文件位置：`stow-dotfiles/zsh/.zshrc`

安装后链接到：`~/.zshrc`

## 环境变量

- `EDITOR=vim`
- `LANG=en_US.UTF-8`
- `LC_ALL=en_US.UTF-8`
- `PATH` 会优先加入：
  - `~/.local/bin`
  - `~/bin`

## 历史记录

- 历史文件：`~/.zsh_history`
- 历史容量：`50000`
- 多个 shell 共享历史：开启
- 忽略重复命令：开启
- 忽略以空格开头的命令：开启
- 执行历史展开前先确认：开启

## 目录行为

- 直接输入目录名可进入目录，例如：`Downloads`
- `pushd` 自动记录目录栈
- 目录栈忽略重复项

## 补全

- 使用 zsh 原生 `compinit`
- 补全菜单支持方向键选择
- 补全匹配忽略大小写
- 补全列表使用彩色显示

## 快捷键

| 快捷键 | 行为 |
| --- | --- |
| `Up` | 搜索以当前输入开头的上一条历史命令 |
| `Down` | 搜索以当前输入开头的下一条历史命令 |
| `Ctrl+Right` | 向前移动一个单词 |
| `Ctrl+Left` | 向后移动一个单词 |
| `Esc+Right` | 向前移动一个单词，兼容部分终端 |
| `Esc+Left` | 向后移动一个单词，兼容部分终端 |
| `Home` | 移动到行首 |
| `End` | 移动到行尾 |
| `Delete` | 删除光标后的字符 |

## Alias

| Alias | 展开为 | 说明 |
| --- | --- | --- |
| `ls` | `ls --color=auto` 或 `ls -G` | Linux/macOS 自动选择彩色输出 |
| `ll` | `ls -lhF` | 长列表，人类可读大小 |
| `la` | `ls -lahF` | 包含隐藏文件的长列表 |
| `rm` | `rm -i` | 删除前确认 |
| `cp` | `cp -i` | 覆盖前确认 |
| `mv` | `mv -i` | 覆盖前确认 |
| `grep` | `grep --color=auto` | GNU grep 下启用彩色匹配 |
| `df` | `df -h` | 人类可读磁盘空间 |
| `du` | `du -h` | 人类可读目录大小 |
| `..` | `cd ..` | 返回上级目录 |
| `...` | `cd ../..` | 返回上两级目录 |
| `zshrc` | `${EDITOR} ~/.zshrc` | 编辑 zsh 配置 |
| `reload` | `source ~/.zshrc` | 重新加载 zsh 配置 |

## Prompt

Prompt 显示：

- 当前 Conda 环境，如果 `CONDA_DEFAULT_ENV` 存在
- 当前目录
- Git 分支
- 命令状态：
  - 成功时提示符为绿色
  - 失败时提示符为红色

## 插件

安装脚本会安装并启用：

- `zsh-autosuggestions`
  - 根据历史和补全给出灰色命令建议
- `zsh-syntax-highlighting`
  - 命令语法高亮
  - 必须最后加载

插件目录：

```bash
~/.zsh/plugins/
```

## 本地配置

`~/.zshrc` 最后会加载：

```bash
~/.zshrc.local
```

这个文件不由 Stow 管理，适合放机器相关配置，例如：

- Conda 初始化
- NVM 初始化
- fzf 初始化
- 公司代理
- 私有 PATH

示例文件：

```bash
examples/.zshrc.local
```
