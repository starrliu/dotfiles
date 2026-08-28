---
name: k8s_job_submit_msra_b200
description: >-
  Use when submitting, monitoring, debugging, or recovering GPU training/processing
  jobs on a Kubernetes cluster with the Volcano batch scheduler (kubectl apply of
  batch.volcano.sh Jobs) — especially on B200 (sm_100) or A100 nodes where torch
  CUDA wheels, per-job code isolation, and preemption recovery are recurring pain
  points. Covers the job YAML skeleton, two code-distribution strategies, the
  torch/CUDA version traps, and how to tell preemption apart from a real crash.
  Examples used are from an MSRA-style bonete05 cluster; adapt the cluster-specific
  values (namespace, queue, PVC, image) to your environment.
---

# Submitting GPU jobs on a Volcano (kubectl) cluster

Battle-tested workflow for launching training / batch-processing jobs on a
Kubernetes cluster that uses the **Volcano** batch scheduler. Concrete examples
come from an MSRA-style cluster (`bonete05` namespace, B200 8-GPU nodes), but the
method is general — swap in your own values where marked **[PROVIDE]**.

## Values you must supply for YOUR cluster/job (**[PROVIDE]**)

The skill's method is generic; these are environment-specific. Ask the user (or
read from a git-ignored config) rather than hard-coding:

| What | Example (bonete05) | Notes |
|------|--------------------|-------|
| namespace | `bonete05` | `kubectl -n <ns>` |
| queue | `bonete05-opp` **or** `bonete05` | both are submittable; `-opp` is the low-priority *opportunistic* queue (gets preempted first) |
| PVC claim | `pvc-vast-bonete05` | mounted at `/data` |
| container image | `pytorch/pytorch:2.8.0-cuda12.8-cudnn9-devel` | must match the GPU arch (see torch traps) |
| GPU count / SKU | 8× B200 (or A100) | `nvidia.com/gpu`, cpu, memory, rdma requests |
| data/code root on PVC | `/data/<user>/...` | persistent across pods |
| secrets | WANDB_API_KEY, HF token, git creds | **never commit**; inject at runtime |

Never invent these — if unknown, stop and ask.

## Submit

```bash
kubectl apply -f job.yaml          # resource kind: batch.volcano.sh/v1alpha1 Job
```

### Minimal Volcano Job skeleton

```yaml
apiVersion: batch.volcano.sh/v1alpha1
kind: Job
metadata:
  name: <user>-<jobname>          # [PROVIDE]
  namespace: <ns>                 # [PROVIDE]
spec:
  queue: <queue>                  # [PROVIDE]  e.g. bonete05-opp
  minAvailable: 1
  plugins: { ssh: [], svc: [], env: [] }
  tasks:
    - name: server
      replicas: 1
      template:
        spec:
          schedulerName: volcano
          restartPolicy: Never
          volumes:
            - name: dshm
              emptyDir: { medium: Memory, sizeLimit: 100Gi }   # /dev/shm for dataloaders
            - name: data
              persistentVolumeClaim: { claimName: <pvc> }      # [PROVIDE]
          containers:
            - name: server
              image: <image>                                   # [PROVIDE]
              volumeMounts:
                - { name: dshm, mountPath: /dev/shm }
                - { name: data, mountPath: /data }
              command: ["/bin/bash","-lc"]
              args:
                - |
                  set -eo pipefail
                  # keep the pod alive after the run so you can debug
                  trap 'echo "Job finished/failed. Sleeping for debug..."; sleep 6h' EXIT

                  # === system deps (only what the image lacks) ===
                  apt-get update -y && apt-get install -y --no-install-recommends \
                    git rsync curl libgl1 libglib2.0-0

                  # === code distribution: see "Code distribution" section ===
                  # === python env: see "torch/CUDA traps" section ===
                  # === run (use .venv/bin/torchrun, NOT `uv run`) ===
              resources:
                requests: { nvidia.com/gpu: "8", cpu: "104", memory: "2600Gi" }
                limits:   { nvidia.com/gpu: "8", cpu: "104", memory: "2600Gi" }
```

Key skeleton choices:
- **`trap '... sleep 6h' EXIT`** — pod stays up after the process exits so you can
  `kubectl exec` in and inspect. Remove for production.
- **`/dev/shm` as Memory emptyDir** — dataloader workers need it; default shm is tiny.
- **`restartPolicy: Never`** — let Volcano reschedule the whole PodGroup, don't
  silently restart in place.

## Code distribution (pick one — both prevent concurrent-job conflicts)

The core problem: N jobs sharing one source dir corrupt each other's build/venv.

### Strategy A — per-job rsync isolation (code lives on the PVC)
Each job copies the source into its own tagged dir with its own venv + uv cache:
```bash
SRC=/data/<user>/code/<project>
DST=/data/<user>/code_copies/<jobtag>          # unique per job
mkdir -p "$DST"; rsync -a --delete --exclude '.venv' "$SRC"/ "$DST"/
cd "$DST"
export UV_CACHE_DIR=/data/<user>/.uv-cache-<jobtag>   # unique per job
# ...build venv inside $DST/.venv...
```
Good when: code is already on the PVC, you iterate fast and don't want to push
git every time. Watch out: the `--exclude '.venv'` means a *stale* broken venv in
the copy can survive — see dist-info trap.

### Strategy B — git clone per job (code lives on GitHub)
Push to remote, then each job clones a fresh dir:
```bash
git clone --depth 1 -b <branch> <repo_url> /data/<user>/runs/<jobtag>
cd /data/<user>/runs/<jobtag>
```
Good when: you want clean, reproducible, naturally-isolated checkouts and don't
mind pushing first. Inject a token for private repos; never bake it into the YAML.

Either way: **one code dir + one venv + one uv cache PER job.** Never shared.

## torch / CUDA traps (the part that actually bites)

### 1. New GPU arch needs a matching torch wheel
B200 is compute capability **sm_100**; A100 is sm_80. A torch that predates the
arch fails at first CUDA op with **`no kernel image is available for execution`**.
Fix: install a wheel built for it, forcing over the image's default:
```bash
uv pip install torch==2.8.0 torchvision==0.23.0 \
  --index-url https://download.pytorch.org/whl/cu128 \
  --force-reinstall --python .venv/bin/python || true
```
Version pairing matters: **torch 2.8.0 ↔ torchvision 0.23.0** (a mismatched
torchvision throws at import). Confirm the pairing for whatever torch you pin.

### 2. force-reinstall leaves a stale dist-info → `version("torch")` returns None
After `--force-reinstall`, the OLD `torch-2.7.x.dist-info` can remain alongside
the new one. Then `importlib.metadata.version("torch")` sees two distributions
and returns `None`, and libraries like transformers crash on
`version.parse(None)` at import. **Always clean the stale metadata:**
```bash
rm -rf .venv/lib/python*/site-packages/torch-2.7*.dist-info
```
This bug hides because `|| true` swallows a failed reinstall and rsync's
`--exclude .venv` preserves the broken venv, so a restart doesn't self-heal.

### 3. `uv run` re-resolves and can downgrade torch
Running via `uv run torchrun ...` may reinstall the locked (older) torch,
undoing your B200 fix. **Call the venv binary directly:**
```bash
.venv/bin/torchrun --nnodes=1 --nproc_per_node=8 --standalone scripts/train.py ...
```

### 4. Checkpoint path nesting
Frameworks that build `checkpoint_base_dir/<exp>/<exp>/step_N` can double-nest;
if a resume can't find weights, print the resolved path and check for an extra
level (e.g. `.../pi0_base/pi0_base/`). Point `--pytorch_weight_path` at the real
leaf.

## Monitor

```bash
kubectl get jobs.batch.volcano.sh -n <ns>                 # STATUS: Running / Pending / Completed / Failed
kubectl logs -n <ns> <jobname>-server-0 | tail -50        # training stdout
kubectl get podgroup -n <ns>                              # Inqueue vs Running — see the queue
kubectl get events -n <ns> --field-selector involvedObject.name=<jobname> | tail
```
Note: with `restartPolicy: Never` + a `trap sleep`, a job shows `Running` during
the debug sleep even after the real work finished — check the logs, not just STATUS.
Multiprocessing worker stdout may not flush to the main log; verify progress by
the **actual output artifacts** (files written to the PVC) when logs look stalled.

## Preemption vs crash — diagnose before reacting

The single most important triage. **Do not resubmit a preempted job** — it just
re-queues; resubmitting wastes quota and does nothing.

| Symptom | Meaning | Action |
|---------|---------|--------|
| Pod `Pending`; events say `0/N nodes are unavailable: Insufficient nvidia.com/gpu / memory / cpu` | **Preemption / no capacity** (common on `-opp` queues) | Wait. Volcano reschedules when capacity frees. Checkpoints protect progress. |
| Pod `Pending`; PodGroup `Inqueue`; other users' jobs `Running` | Queue quota full (opportunistic queue starved by higher priority) | Wait, or move to a non-opp queue if you have quota. Can't fix from job side. |
| Pod `Failed`; log has `Traceback` / `ChildFailedError` | **Real crash** | Read the log; fix; resubmit. |
| `exitcode -11` / `Signal 11 (SIGSEGV)` | Native crash (bad frame decode, /dev/shm, native race on resume) | Often transient — delete + resubmit; it resumes from checkpoint. Recurring ⇒ investigate the native lib. |
| `TypeError: expected string or bytes-like object, got 'NoneType'` around `version.parse` | The dist-info trap (#2 above) | Clean stale `torch-2.7*.dist-info`, resubmit. |
| tensor shape mismatch on resume (e.g. 1240 vs 1274) | model config drift vs checkpoint (e.g. wrong `action_horizon`) | Match the config to the checkpoint that produced it. |

## Preemption recovery (make jobs survive being killed)

Opportunistic queues get preempted often. Design for it:
- **Save checkpoints frequently.** `save_interval` should be small enough that a
  preemption loses only minutes, not hours (e.g. every 1000 steps, verified: a
  job preempted at ~7700 resumed cleanly from its 7000 checkpoint).
- **Always launch with `--resume`** (or the framework's equivalent) so a
  rescheduled pod continues instead of restarting from 0. Make resume *gracefully
  start fresh* when no checkpoint exists yet.
- Write checkpoints to the **PVC** (`/data/...`), never to the pod's ephemeral
  disk — the pod is destroyed on preemption.
- After a preempted job reschedules it re-runs the whole `args` (apt/pip/venv
  rebuild), so keep setup idempotent and reasonably fast.

## Cluster-wide preemption

If ALL your jobs go `Pending` at once, a high-priority tenant grabbed the pool.
It's a scheduling event, not your bug. Don't churn — record the last-known step of
each job, let Volcano restore them, and verify each resumes from its checkpoint.

## Etiquette / safety

- Confirm remaining submission quota before launching many jobs on shared clusters.
- Keep secrets (WANDB/HF/git tokens) out of committed YAML — inject at runtime.
- Record job state in a running `status.md` so you can recover after context loss:
  which jobs exist, their last step, and any fix applied.
