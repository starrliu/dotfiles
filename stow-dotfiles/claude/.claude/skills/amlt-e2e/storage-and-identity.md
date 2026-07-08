# 存储、身份与 blob I/O —— 提交前就该懂、不然会误判的那些事

[setup.md](setup.md) 的配套文档。`setup.md` 负责让你拿到一个 checkout 好的
project 和一个可见的 target。本文件覆盖的是**配置和监控里那些"看起来对、其实会坑你"的
部分**：job 实际能读写哪个存储、哪个身份被授权、以及——很关键——**blobfuse 挂载和
`blob list` 都会骗你**，让正常运行看起来像失败。

**这不是一份"出问题了再翻"的 debug 手册。** 至少 §1（存储绑定模型）和 §6（blobfuse /
list 会骗你）属于**提交前就要内化、监控时一直记着**的知识：如果你不提前知道 blobfuse
不 flush、`blob list` 计数会严重滞后，你会把"日志 0 字节""进度数不涨"当成卡死或失败，
从而做出错误的 cancel/重提（我就这么误判过一次，见 §7）。建议第一次提交前通读一遍。

适用于 Manifold (Singularity) / AML cluster 后端。Local (Docker) 不涉及这些。

---

## 1. 权限的根在 storage 绑定，不在 YAML

当一个 job 因为 `PermissionDenied` / `AuthorizationFailed` 读不到 checkpoint、
写不了结果而挂掉时，第一反应往往是去改 run config 里的 `storage:` 块。**但这几乎从来
不是解法。** 真正决定 job 能碰哪些存储的，是 **amlt *project* 绑定的那个 storage account**
（`amlt project create <project> <account>`），加上 **job 的身份是否在那个 account 上
被授权**。

症状 → 真因 → 解法：

| 症状 | 真因 | 解法 |
|---|---|---|
| ckpt/结果报 `PermissionDenied`，YAML 看着没错 | project 绑到了 account A，但 job 的 UAI 只在 account B 有权限 | 把 project 重新绑到 UAI *能访问*的那个 account（见下） |
| 代码包上传到了意外的位置 | 上传目的地跟随 **project** 的 storage 绑定，不是 run config | 看 `amlt project` 输出；绑错就重绑 |
| 你本地能跑，job 里失败 | 你是用*你自己*凭证的挂载读的；job 用的是它的**托管身份** | 确认是 **UAI**（不是你的登录账号）被授权了 |

**终结猜测的诊断命令：** 打印 project 实际绑定的是什么，并确认身份在它上面有
*account 级*的角色：

```bash
amlt project                       # 当前 project + 它的 storage account + subscription
# 然后在 Azure portal / az CLI 里确认 UAI 在那个 account 上有
# "Storage Blob Data Contributor"（account 范围，不是 container 范围）。
```

如果 UAI 和 storage account 不在同一个 subscription，角色分配经常会静默地不生效。
优先用一个**和 storage account 同一 subscription**（或被显式授予 account 级权限）的身份。
重绑 project：

```bash
# 通过把 project 重新 create 到 UAI 能访问的 account 来重绑。
# （project 名不变也可以，它只是把绑定重新指向。）
amlt project create <project> <reachable-storage-account> -d "$AMLT_PROJECT_DIR"
```

## 2. 优先用自动挂载的 project 存储，而不是手写 `storage:` 块

amlt 会把 **project 的**存储（project 绑定的那个 account/container）自动挂载到
**`/mnt/default`**，可读写。把输入（checkpoint）和输出（结果）都放这里，命令里引用
`/mnt/default/...` 即可。不需要 `storage:` 块。

**不要条件反射地加一个 `is_output: true` 的 `storage:` 条目。** 那会让 amlt 创建一个
*独立的托管 datastore* —— 一个全新的、空的 container，**不是**你数据所在的那个。经典翻车：

```yaml
# 反面教材 —— 创建一个空 datastore；你的 ckpt 不在里面
storage:
  myout:
    storage_account_name: <acct>
    container_name: <container>
    is_output: true
    mount_dir: /mnt/myout
```
→ job 启动后，`/mnt/myout/.../ckpt` 报 `FileNotFound`，因为 amlt 挂载的是一个新的空存储，
不是那个装着你 checkpoint 的 container。

只有当你确实需要一个 project 没绑定的*第二个* account/container 时才加显式 `storage:` 块
—— 而且加了之后，依赖它之前先确认挂载里真的有你的数据。

## 3. SAS token 认证：提交时通过环境变量注入

当 storage account 用 SAS（而不是 project 的托管身份）来让*提交端*的 CLI 推送代码包时，
amlt 会从一个以 account 命名的环境变量里读 token：

```bash
# 命名规则：AMLT_STORAGE_<account 名大写>_KEY
export AMLT_STORAGE_<ACCOUNTUPPER>_KEY="<完整的 SAS token 字符串>"
amlt run config.yaml <exp> --yes
```

- amlt 会自动识别这个值是 SAS（一个 `?sv=...&sig=...` 字符串）而不是 account key
  —— 你不用额外标注。
- 如果 job 同时碰**两个** account（比如 project 存储 + 第二个 data share），`amlt run`
  之前把**两个** `AMLT_STORAGE_*_KEY` 都 export。
- **SAS token 会过期。** 记下过期时间（在 token 的 `se=` 字段或你的 mount yaml 里）。
  开始一个长 sweep 前，确认它不会跑到一半失效；失效的 SAS 会导致新提交失败、以及任何依赖
  它的 in-job blob I/O 失败。

## 4. Singularity job 里会咬人的字段

对 `service: sing` 的 job，除了 `setup.md` 里的基础项：

```yaml
jobs:
- name: ...
  sku: NDv4:1xG8-IB        # 8×A100 节点；确认这个 series 在 target 上存在
  identity: managed         # 用 workspace/job 的托管身份
  sla_tier: Standard        # ← 跟 target 相关！见下
  priority: medium
  submit_args:
    env:
      # 通过指定 UAI 授权 job 访问 project 的 blob datastore。
      _AZUREML_SINGULARITY_JOB_UAI: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<uai-name>
```

- **`sla_tier` 是每个 target 各不相同的。** 某个 VC 可能只提供部分 tier（比如一个
  A100-40GB 池只有 `Standard`/`Basic`，没有 `Premium`）。如果提交时 `sla_tier` 报错，
  **删掉这一行**让平台用 target 的默认值，或查允许的值
  （`amlt schema show config jobs.sla_tier`）。删掉后看一下提交的 job 的 FLAGS 列
  —— 默认 tier 可能不一样（比如 `PRM`）。
  - 用 gen 脚本生成 yaml 时，可以传**空串** `--sla_tier ""`：脚本里通常是
    `if args.sla_tier:`，空串是 falsy，于是生成的 yaml 干脆不含 `sla_tier` 行（已验证）。
- **`sla_tier` 与抢占。** Singularity 上 `Standard` 优先级低，**会被 Premium 任务抢占**：
  被抢占时 job 退回 `queued`（不是 failed），且之前的 setup 白跑。表现为一个 job
  setup 跑了很久、刚要出结果却退回排队。大规模评测优先用 **Premium**（很多 target 默认
  PRM，只有部分老池只能 Standard）。判断是抢占还是 hang：抢占会退回 queued，hang 则
  job 一直 running 但不产出。

## 5. 池满了就换 target（`TooManyRequests`）

```
UserError TooManyRequests: Queued resource count 15006 has reached/surpassed
the configured maximum value of 15000.
```

这是**整个 cluster 的排队配额上限**，不是你的错，也不是配置错误。两种应对：取消你自己
排队中的 job 来腾配额，或者**换到同一 resource group 里的另一个 target** —— 通常只要改
一行。

```bash
# 找同类 target（同 RG/subscription ⇒ 身份和存储通常通用）。
amlt target list <service>           # 名字 + RG + 加速器类型
amlt target list <service> -v        # instance series（确认你要的 SKU 存在）
```

换法：复制 YAML，改 `target.name`，并**去掉任何 target 专属的 `sla_tier`**（§4），
让新 target 用自己的默认值。同 resource group + 同 workspace ⇒ UAI 授权和
`/mnt/default` 挂载通常不变就能用 —— 但**第一次跑时确认一下**（盯着有没有
`PermissionDenied`），因为不同 VC 的身份授权可能不同。

## 6. blobfuse 会骗你 —— 一切以真实 blob 为准

blobfuse 挂载（本地那个 `~/blobs/...` 目录）是个**缓存**，不是 blob 本身。两种会让你误判
"成功了"好几个小时的失败模式：

**(a) 大文件写入不 flush。** 把一个大文件（比如 11 GB 的 checkpoint）`cp` 到挂载点会
瞬间返回、`ls` 本地也看得到 —— 但那些字节根本没到 blob。小文件和目录能正常同步，所以
这种"部分成功"会掩盖问题。**大文件上传用 azcopy 那条路（它会做 md5 校验）：**

```bash
amlt storage upload <local> <remote>      # azcopy + 校验和；大文件用这个
```

**(b) 打开中的文件显示 0 字节 / 时间戳不动。** 一个正在运行的进程*直接写到挂载点*的
日志，在文件 close 之前是不可见的 —— 整个写入期间它都显示 0 字节、时间戳停在过去。
这种情况下你**没法区分"卡死"还是"正在写"**。（修法见 [observability.md](observability.md)：
日志先写本地磁盘，close 时再拷到 blob。）

**(c) 列举/计数也不可靠 —— `az storage blob list` 的计数会严重滞后。** 高频写入时，
`list ... length(@)` 返回的数量可能比实际少很多（最终一致性延迟）—— 实测见过真实 6900+
个文件、list 只报 4300。**这会让你误判进度甚至误判 job"卡死"。**

**铁律：永远不要信挂载来确认上传、也不要用它读运行中 job 的输出或数进度。** 要么查
**真实 blob**，要么用 azcopy 把文件拉到本地再统计：

```bash
# 方式一：列举真实大小（完全绕过 fuse 缓存）。注意 list 的"计数"仍可能滞后，
# 看具体文件名/大小比看 length(@) 可靠。
az storage blob list --account-name <acct> --container-name <container> \
  --prefix "<path>/" --sas-token "$SAS" \
  --query "[].{name:name, bytes:properties.contentLength}" -o tsv

# 方式二（推荐用于"数有多少结果/统计指标"）：azcopy 把小文件批量拉本地再算。
# 几千个文件几秒搞定，本地统计飞快，且数量准确。
# ⚠️ SAS 要去掉开头的 '?'（mount yaml 里的 sas 带前导 '?'，拼到 URL 上会变双问号→403）。
SAS_RAW="$(grep -E '^\s*sas:' <mount yaml> | sed -E 's/^\s*sas:\s*//')"; SAS="${SAS_RAW#\?}"
azcopy copy "https://<acct>.blob.core.windows.net/<container>/<path>/?${SAS}" \
  /tmp/local/ --recursive --include-pattern "*_summary.json"
```

## 7. 别把"blob 同步慢/计数滞后"误判成 hang —— 先用 azcopy 核实再动手

跑了很久的 job 有时会**看起来卡死**：job 在 amlt 里显示 `running`、不报错，但你盯着
`blob list` 的计数好几十分钟"不涨"，于是怀疑 worker hang 了。

**⚠️ 教训（亲身踩过）：这种"hang"很可能是假的。** 真凶往往是 §6 说的
**`blob list` 计数严重滞后 + blobfuse 同步慢** —— job 其实一直在正常产出，只是
`list ... length(@)` 报的数字远低于真实值（实测见过真实 6900+、list 报 4300）。当时我
据此判断"job hang 了"并 cancel+重提，**后来用 azcopy 把文件拉到本地一数，发现根本没卡，
那次 cancel 是多余的、还白白损失了进度和一轮 setup。**

**所以判定 hang 之前，必须先排除"是 list 在骗我"：**

```bash
# 用 azcopy 拉真实文件到本地数（绕过 list 的滞后计数），看产出的"时间戳"是否在前进。
SAS_RAW="$(grep -E '^\s*sas:' <mount yaml> | sed -E 's/^\s*sas:\s*//')"; SAS="${SAS_RAW#\?}"
azcopy copy "https://<acct>.blob.core.windows.net/<container>/<path>/?${SAS}" \
  /tmp/local/ --recursive --include-pattern "*.json"
# 看最新文件的 creationTime：若在最近几分钟内 → 在产出，没 hang，别动它。
```

**只有当 azcopy 确认产出时间戳确实停住了**（比如 30 分钟+ 没有任何新文件落地，且多个并行
job 同时停），才是真 hang。真 hang 的恢复办法是 **cancel + 重提**（结果幂等续跑时零数据
损失）：

```bash
amlt cancel <exp> --yes        # 用 --yes；amlt cancel 不读 stdin，`yes |` 管道无效
amlt run <yaml> <new-exp> --yes   # 幂等从断点续跑；换新 exp 名避免和 killed 记录混淆
```

补充：per-episode 的 timeout 兜底不了"整体 hang"（只在单个 episode 超时才触发）；以及在
无 tty 环境（自动化 loop）里 `amlt ssh` 用不了（`Host key verification failed`），所以
判断只能靠 azcopy 拉本地看产出时间戳。**核心原则：azcopy 核实 > 相信 list 计数 > 凭感觉
cancel。**

## 8. HF / 外部下载在 cluster 节点上会超时

cluster 节点经常无法可靠访问 `huggingface.co` / CDN（连接重置、在 `Fetching N files 0%`
卡好几分钟）。任何在 job 启动时下载权重或资源的 setup 步骤都是潜在的 hang。**改成预先放到
blob，再从 `/mnt/default` symlink/拷贝**，不要在 job 里现下。如果 setup 脚本有
`--assets_cache` / 本地缓存的 flag，把它指向预放好的路径，并确认那个路径**在节点上真的
存在**（路径错了会静默回退到走网络下载）。

---

## 提交前快速 checklist

- [ ] project 绑定到了 job 的 UAI 真正能访问的 storage account（§1）
- [ ] 输入+输出都在 `/mnt/default` 下；没有多余的 `is_output` datastore（§2）
- [ ] 所有需要的 `AMLT_STORAGE_*_KEY` SAS 变量都已 export；不会跑到一半过期（§3）
- [ ] `sla_tier` 对*当前这个* target 有效（或干脆省略）；大规模优先 Premium 防抢占（§4）
- [ ] 大文件用 `amlt storage upload` 上传、用 `az`/`azcopy` 核实（§6）
- [ ] 进度/结果统计用 azcopy 拉本地，不信 blobfuse 挂载和 list 计数（§6）
- [ ] 关键路径上没有 in-job 的 HF/外部下载（§8）
