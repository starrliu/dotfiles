# Paseo：Windows 连接远程 Linux agent

Linux 上运行 Paseo daemon 和 agent，Windows 桌面端通过 SSH 查看输出、发送任务和处理权限请求。
无需开放服务器的 6767 端口，也无需启用 Paseo relay。

## 安装服务端

要求 Linux/systemd、Node.js 22 或更高版本及 npm。请使用平常运行 agent 的用户安装，不要加 `sudo`。
如果 Node 不在当前 PATH 中，脚本会尝试加载已有的 `${NVM_DIR:-~/.nvm}/nvm.sh`；
仍不可用时，先安装或切换 Node（例如 `nvm install 22`）。

```bash
cd ~/dotfiles
./install_paseo.sh
```

脚本会：

- 将 `@getpaseo/cli` 安装到 `~/.local`，默认固定版本 `0.11.1`。
- 仅在 `~/.paseo/config.json` 不存在时复制 [初始配置](../examples/paseo/config.json)，监听 `127.0.0.1:6767`，关闭 relay。已有配置完整保留。
- 根据本机 Node 路径和安装时的 PATH 生成 systemd 用户服务，备份有变化的旧 service 文件。
- 启用 `paseo.service`，尝试启用 linger，使退出 SSH 后及机器重启后服务仍可运行。
- 启动未运行的服务。已有服务或手动启动的 daemon 不会被自动重启。

若启用 linger 被系统策略拒绝，执行脚本提示的 `sudo loginctl enable-linger <用户名>`。
检查状态：

```bash
export PATH="$HOME/.local/bin:$PATH"
paseo daemon status --home ~/.paseo
systemctl --user is-enabled paseo
loginctl show-user "$(id -un)" -p Linger
```

请确保 `~/.local/bin` 也在日常 shell 的 PATH 中。使用自定义 `XDG_CONFIG_HOME` 时，
service 位于该目录下的 `systemd/user/`，否则位于 `~/.config/systemd/user/`。

Paseo 配置会被应用写入，也可能包含密码哈希或 provider 配置，因此这里使用模板初始化，
不通过 Stow 链接运行中的 `config.json`。整个 `~/.paseo/`（凭据、配对密钥、日志、会话等）留在本机。
服务会记录安装时的可执行文件搜索路径，不会复制当前终端的 API key 等环境变量。
需要额外服务环境变量时使用 `systemctl --user edit paseo` 在本机配置。

## Windows 桌面端

先在 PowerShell 验证 Windows OpenSSH 能免交互连接。例如现有 Host 别名为 `5090_yuming`：

```powershell
ssh -o BatchMode=yes yuming@5090_yuming "echo SSH_OK"
```

应输出 `SSH_OK`。Paseo 读取 Windows 的 `%USERPROFILE%\.ssh\config`，
使用 SSH 密钥或 SSH agent；不弹窗询问 SSH 登录密码。
若验证失败，先用普通 `ssh yuming@5090_yuming` 处理主机指纹，再检查密钥/SSH agent 配置。

打开 Paseo → **Settings → Add host → Remote SSH**，输入：

```text
ssh://yuming@5090_yuming
```

换机器时替换用户名和 Host 别名。默认初始配置未设置 daemon 密码，**Daemon password** 留空；
保留的配置如果已有密码，请填写该密码。找不到 Remote SSH 入口时先更新 Windows 桌面端。

SSH URL 的 `:端口` 表示 SSH 服务端口，默认远端 daemon 端口为 `6767`。
SSH 配置中的 `Port`、`IdentityFile`、`ProxyJump` 可以继续使用。
如果需要显式指定 SSH 端口和不同的 daemon 端口：

```text
ssh://user@host:2222?daemonPort=7777
```

## 使用 agent

Paseo 使用 Linux 用户已有的 agent CLI 和登录状态，安装 Paseo 本身不会安装或登录 agent。
连接后在桌面端选择远端项目目录，选择可用 provider 并创建会话。
例如检查 Codex 是否被 daemon 找到：

```bash
paseo provider diagnostic codex
```

也可以在远端终端启动任务，随后从 Windows 查看：

```bash
cd ~/projects/my-project
paseo run --provider codex --background "概述这个项目，不要修改文件"
paseo ls
```

Paseo 不会自动接管所有外部终端正在运行的 agent。已有 provider 会话可按 ID 导入，
之后从 Paseo 继续使用；不要在两个客户端同时驱动同一会话。例如：

```bash
paseo agent import <Codex会话ID> --provider codex --cwd /项目绝对路径
```

## 更新、维护与卸载

重复执行安装脚本会保留配置。需要其他 Paseo 版本时：

```bash
PASEO_VERSION=0.11.1 ./install_paseo.sh
# 也可以显式使用 PASEO_VERSION=latest
```

脚本不会自动重启已有服务。升级 CLI、切换/移除 nvm Node 版本或修改服务环境后，
在方便中断现有会话时重新运行脚本并重启服务，更新进程使用的路径和版本：

```bash
systemctl --user restart paseo
paseo daemon status --home ~/.paseo
paseo provider diagnostic codex
```

如果之前用 `paseo daemon start` 手动启动，脚本会保留该 daemon 并提示切换方式。
在方便中断会话时执行：

```bash
paseo daemon stop --home ~/.paseo
systemctl --user start paseo
```

排障及停止服务：

```bash
journalctl --user -u paseo -n 50 --no-pager
tail -n 50 ~/.paseo/daemon.log
systemctl --user stop paseo
```

卸载服务与 CLI（保留本地配置和会话）：

```bash
systemctl --user disable --now paseo
rm "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/paseo.service"
systemctl --user daemon-reload
npm uninstall --global --prefix "$HOME/.local" @getpaseo/cli
```

linger 是用户级设置，其他后台服务可能依赖它，因此卸载时不自动关闭。

参考：[安装](https://paseo.sh/docs)、[连接方式](https://paseo.sh/docs/connectivity)、
[配置](https://paseo.sh/docs/configuration)、[CLI](https://paseo.sh/docs/cli)。
