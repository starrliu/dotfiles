# 我的环境 —— 账户资源与凭证清单（个人）

[storage-and-identity.md](storage-and-identity.md) 的个人版配套。那个文件是通用 playbook，
本文件只**罗列我账户下有哪些 amlt 资源、以及对应的凭证/坐标** —— 复制即用，与任何具体
项目无关。

> ⚠️ 含标识信息（subscription、UAI、storage、SAS 取法）。不要放进共享仓库 / 公开配置。

## Subscription

- **Singularity Shared**：`c4c534bc-9978-4974-9c87-551f7c5754ef`（target / project / UAI 一）
- **eaiws**：`b069070b-b0db-4af5-9d76-0f329c377f9e`（UAI 二 `eaiws4storage` / `eaidatashare`）

## Storage account

| account | container | 备注 |
|---|---|---|
| `msrashamlws4466460092` | `v-xingyumliu` | 存储一；与uai msra-sh-aml-uai配对使用 |
| `eaidatashare` | `v-xingyumliu` | 存储二；与uai eaiws配对使用 |

- job 内挂载点：`/mnt/default`（自动挂载 project 绑定的存储，可读写）。

## 身份（UAI）

两个 UAI，各配一个 storage account（见上表）。放进
`jobs[].submit_args.env._AZUREML_SINGULARITY_JOB_UAI`，job 设 `identity: managed`。

**UAI 一：`msra-sh-aml-uai`** —— 配 `msrashamlws4466460092`（同 Singularity Shared 订阅，
account 级 *Storage Blob Data Contributor*，无跨订阅问题；project 绑这个 account）：

```
/subscriptions/c4c534bc-9978-4974-9c87-551f7c5754ef/resourceGroups/msra-sh-aml-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/msra-sh-aml-uai
```

**UAI 二：`eaiws4storage`** —— 配 `eaidatashare`（在另一订阅 `b069070b...` 的 `eaiws` RG）：

```
/subscriptions/b069070b-b0db-4af5-9d76-0f329c377f9e/resourceGroups/eaiws/providers/Microsoft.ManagedIdentity/userAssignedIdentities/eaiws4storage
```

- `submit_args.env` 完整示例（含常带的 MKL 设置）：
  ```yaml
  submit_args:
    env:
      MKL_THREADING_LAYER: GNU
      _AZUREML_SINGULARITY_JOB_UAI: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<uai>
  ```
- 用哪个 UAI 取决于 job 要读写哪个 storage：访问 `msrash...` 用 UAI 一，访问
  `eaidatashare` 用 UAI 二。

## amlt project / workspace

- project：`rtceval2`（绑定 `msrashamlws4466460092`，**不是** `eaidatashare` —— 绑错
  eaidatashare 是最初 `PermissionDenied` 的根因）。
- workspace：`msra-sh-aml-ws`（Singularity / `service: sing`）。

## Targets（NDv4 = 8卡A100）

| target | RG | sla_tier | 备注 |
|---|---|---|---|
| `palisades33` | gcr-singularity | 空 → 默认 `PRM` | PRM 稳定不被抢 |
| `msrresrchvc` | gcr-singularity-resrch | 空 → 默认 `PRM` | PRM 稳定 |
| `msrresrchbasicvc` | gcr-singularity | `Standard` | 只有 STD，会被 Premium 抢占；队列满时报 `TooManyRequests` |

- SKU：`NDv4:1xG8-IB`（1× 8卡 A100 节点），三个 target 都支持。
- 同 RG/workspace ⇒ 换 target 只改 `target.name`（palisades/msrresrchvc 用空 sla_tier，
  basicvc 加 `--sla_tier Standard`）。
- 平台镜像：`amlt-sing/acpt-torch2.8.x-py3.10-cuda12.6-ubuntu22.04`。

## SAS token（每次提交/查询前 export）

```bash
export AMLT_STORAGE_MSRASHAMLWS4466460092_KEY="$(grep -E '^\s*sas:' /home/v-xingyumliu/blobs/mount_msrash.yaml | sed -E 's/^\s*sas:\s*//')"
export AMLT_STORAGE_EAIDATASHARE_KEY="$(grep -E '^\s*sas:' /home/v-xingyumliu/blobs/mount_eaidatashare.yaml | sed -E 's/^\s*sas:\s*//')"
```

- **过期：两个都是 2026-06-30**，之后开始长 run 前需重新签发。
- 用 azcopy 直接访问 blob 时，SAS 要**去掉开头的 `?`**（mount yaml 里带前导 `?`，拼到
  URL 会变双问号 → 403）：`SAS="${SAS_RAW#\?}"`。

## amlt CLI

- 二进制：`/home/v-xingyumliu/miniconda3/envs/amlt/bin/amlt`（在 `amlt` conda env，
  base/PATH 里可能没有）。
- 命令需在文件系统沙箱外运行（碰 `~/.config`、网络、az 凭证）→ `dangerouslyDisableSandbox`。
- 常用：
  - `amlt status <exp>` —— FLAGS 列显示 tier（`STD`/`PRM`）；STATUS：完成=`pass`、取消=`killed`。
  - `amlt log view <exp> :<job> -n N` —— job 引用带冒号前缀。
  - `amlt cancel <exp> --yes` —— 必须 `--yes`，不读 stdin。
  - `amlt ssh` 在无 tty 环境（自动化 loop）里用不了（`Host key verification failed`）。
