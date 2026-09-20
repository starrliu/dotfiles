---
name: amlt-e2e
description: >-
  Use when the user wants to submit, monitor, debug, or recover ML experiments
  on AzureML (AML), Manifold (Singularity), Volcano, or Local (Docker) via the
  amlt CLI. Covers project setup, amlt run config authoring, status/watch/logs,
  results retrieval, and rerun/resume workflows.
---

### E2E Skill — AzureML (AML), Manifold (Singularity), Volcano & Local (Docker)

Use this skill for end-to-end workflows (submit → monitor → debug → recover). For per-command reference — every option, every subcommand — run `amlt <cmd> --json-help` or `amlt --json-help` for structured JSON.

## Scope

Covers cluster ops via `amlt` end-to-end — submit, monitor, debug, results, recovery — for AzureML (AML), Manifold (Singularity), Volcano, and Local (Docker). Backend-native commands (`kubectl`, `az ml`) are used **only** when `amlt show <exp> :<job>` prints them as ready-to-run examples — and only then. Never construct backend commands yourself. The Local backend runs the job in a Docker container on the current machine *through amlt* — this is **not** the same as bypassing amlt to run a script directly (see *Operating principle*).

**Reference files:**
- [setup.md](setup.md) — first-time project checkout/create, workspace, target.
- [storage-and-identity.md](storage-and-identity.md) — **read once BEFORE your first submit, not just when debugging.** Covers the storage-binding permission model AND the traps that make a healthy run look broken: **blobfuse doesn't flush, and `blob list` counts lag badly** — so "0-byte logs" / "progress count not moving" are NOT failures. Knowing this up front prevents wrong cancels. Also: `/mnt/default` vs `is_output`, SAS injection, `sla_tier`/preemption per target, `TooManyRequests` cluster-switch, and using azcopy to read true progress.
- [observability.md](observability.md) — wire this in *before* debugging a distributed job: unbuffered + local-then-blob logs + per-unit `timeout` + smoke-gate discipline, so a remote job tells you where it's stuck.
- [troubleshoot.md](troubleshoot.md) · [recover.md](recover.md) — runtime failures; rerun/resume.
- `my-env.md` — *personal*: concrete project/storage/UAI/target/SAS coordinates (gitignored; present only on this machine).


## Operating principle

**Everything goes through amlt — submitting, monitoring, recovering jobs —
unless the user explicitly tells you to use something else.** amlt runs on
shared infrastructure (clusters, storage, quota, identities owned by a team)
and keeps it accountable: snapshotting, identity, quota, security scanning,
results under a known experiment. So routing around it is never a safe
shortcut (no running scripts outside amlt, no editing past schema errors, no borrowing an
identity, no disabling a security check) — when you'd otherwise go around
amlt, stop and ask. If the user explicitly chooses another path, honor it —
but echo the exact command rather than improvising. When a rule and
convenience conflict, prefer the rule; when no rule fits, reason from this
intent. (Running `amlt run -t local` is *not* going around amlt — it is
amlt's Local backend, which executes the job in Docker for you.)

## Critical guardrails

These four are the rules the Quick start path assumes. The full guardrail list (with the rest) is in the Guardrails section below; read it once before your first run.

- **discover-configs-only-in-cwd.** Do not `cd`,
  recurse, or inspect parent/sibling directories to find configs or
  project values.
- **generate-configs-with-amlt-template.** Run
  `amlt template -t <service-or-target> -f <path> -y`, then fill placeholders.
- **do-not-fall-back-to-local-execution.** If amlt
  cannot reach the target, stop and report.
- **yield-after-submit.** After `amlt run` returns
  experiment names, report them and wait for the next user request —
  **unless** the user explicitly asked you to wait for the job to finish
  or succeed, in which case block until it reaches a terminal state (see
  *Monitor*) and report the outcome before yielding.

## Quick start (zero-config path)

Follow this path first. Only fall back to [setup.md](setup.md) if a
step below fails — it picks up from step 1's detection, so don't
re-probe. Read the *Guardrails* section once before your first run
— the steps below assume those rules (cwd-only discovery, never
hand-write YAML, yield after submit, never fall back to local
execution).

1. **Detect what's installed and bound.** Don't ask the user anything
   yet — run these cheap local probes (they read `.amltconfig` and the
   installed package). Defer the slow `amlt target list` until you
   generate the config (it needs the chosen backend anyway)

   ```bash
   amlt --version    # CLI installed?
   amlt project      # active project for THIS directory?
   ```

   **`amlt --version` fails** → amlt isn't installed. Stop; install via
   [setup.md](setup.md). Nothing else matters until this passes.

   **`amlt --version` succeeds** → resolve the project. The active project
   is a *default, not a verdict*: use it unless the user named a different
   project or asked to create one. `amlt project` resolves from the
   **current directory**, so run it in the cwd you were given — `cd`-ing
   first reads a different project.

   | `amlt project` returns | User named a project / asked to create? | Do this |
   |---|---|---|
   | A project | No | **Use it.** Echo its name and continue — don't ask. |
   | A project | Yes, a *different* one | Don't silently use the active one. **Establish the named project** (below), confirm first. |
   | Nothing | No | **Ask for the project name** (not "new or existing?" — `checkout` answers that), then **establish** it. |
   | Nothing | Yes | **Establish the named project** (below). |

   When you use the active project, reuse the project name, storage
   account, container, and subscription it prints; don't ask the user for
   them.

   **Establish a project** — go to [setup.md](setup.md) — *Checkout or
   Create the project*, then return here.

2. **Reuse a config only from the current directory.** Scan `.` for an
   `amlt run` config — **cwd only**, per `discover-configs-only-in-cwd`.
   The cwd is the directory the caller (or parent skill) gave you; if the
   user named one explicitly (e.g. *"Project directory:
   `experiments/hello_world`"*), `cd` there **once** and treat it as fixed.

   ```bash
   # cwd-only scan. Classifies each YAML in the current directory by its
   # target.service. Assumes one `service:` line per config (true for
   # amlt-template output). nullglob so "no YAMLs" yields no output, not
   # the literal glob. Manifold has several synonyms (manifold/mani/
   # singularity/sing) — all are in scope, as are aml, volcano, and local.
   shopt -s nullglob
   for f in *.y*ml; do
     [[ -f "$f" ]] || continue
     svc=$(grep -oE '^[[:space:]]*service:[[:space:]]*"?(manifold|mani|singularity|sing|volcano|aml|local)"?' "$f" 2>/dev/null \
           | grep -oE '(manifold|mani|singularity|sing|volcano|aml|local)' | head -1)
     case "$svc" in
       manifold|mani|singularity|sing) echo "$f  (in scope: manifold)" ;;
       volcano)      echo "$f  (in scope: volcano)" ;;
       aml)          echo "$f  (in scope: aml)" ;;
       local)        echo "$f  (in scope: local)" ;;
     esac
   done
   ```

   Act on the scan result:

   - **No config in cwd (in-scope or out-of-scope).** Generate a fresh
     config (next section). Don't widen the search to find one.
   - **One match, backend agrees with the user's intent.** Read it; echo
     back its path, `target.service`, `target.name`, and job names. Wait
     for the user to confirm before `amlt run` — a wrong-config
     submission consumes quota and leaves results under a misleading
     experiment name, not silently reversible.
   - **Multiple matches.** List them; ask which to use.
   - **Other cases — stop and ask before submitting:**
     - Match's `target.service` differs from the backend the user named
       (e.g. config is `volcano`, user asked for Manifold). Offer to
       (a) submit to the config's backend, (b) copy the file and rewrite
       for the requested backend, or (c) write a fresh config. Do not
       silently translate.
     - User asked for a *new* experiment but a config already exists.
       Copy to a new path; do not overwrite.
     - User pointed at a specific file (e.g. *"use
       `../harness/cluster.yaml`"*). Use that path directly — do **not**
       `cd` to its directory (`discover-configs-only-in-cwd`). Echo
       path + target + jobs, then wait for "go".

3. **Generate a minimal config (only if step 2 found nothing).** This is
   the **only** way to generate a config — no hand-written files allowed:

   ```bash
   amlt template -t <target-or-backend> -f <config.yaml> -y
   ```

   Never hand-type YAML keys, paste a config from memory, or `cat >`/
   heredoc one. After generating, your edits are limited to filling in
   values: the `<placeholder>` markers and any field an inline comment
   marks `REQUIRED` (e.g. `code.local_dir`, Volcano's `queue` and
   `pvc_name`). Don't restructure the scaffold, swap the image, or change
   the `command:` form. About to author or rewrite YAML by hand? **Stop**
   and run `amlt template`.

   `-t/--target` takes **one** value — a backend keyword, a target name,
   or a cluster codename:

   - **Backend keyword** (`aml` / `manifold` / `volcano` / `local`) → uses
     that backend; leaves `target.name` a placeholder for you to fill.
   - **Target name** → Amulet looks it up (same source as `amlt target
     list`), picks the backend, and fills in `target.name` automatically.
   - **Cluster codename** → an informal cluster nickname (not a backend
     keyword, not in `amlt target list`, sometimes looking like a GPU SKU).
     Don't guess the backend or ask — pass it straight to `amlt template -t
     <codename>`: amlt maps it to the right backend (or errors if unknown)
     and leaves `target.name`/`queue`/`pvc_name` as placeholders. Only ask
     if `amlt template` rejects it.
   - **Local** needs no target name or `amlt target list` — `-t local` runs
     in a Docker container on this machine.
   - **Neither given** → ask. Don't guess (a cwd config's `service:` line
     doesn't count); CPU SKUs exist on all backends, so a CPU-only job
     does not pin the backend.

   Add `-d` for multi-node distributed, `-n N` for N extra job entries.
   See `amlt template --json-help` for the full flag list.

   **Inspecting targets.** `amlt --json-tables target list <service>`
   lists every target with its accelerators, series, and bound
   workspace. To inspect **one** target's SKUs, instance series, and
   quota, run `amlt --json-tables target info -t <target>` — one call,
   don't re-list. There is **no** `amlt target show`. On `target
   list`/`info`, the specific target goes after `-t` (`-t <target>`,
   not positionally), and `-v` is a repeatable count flag for extra
   detail (`-v -v`), never a numeric argument (`-v 2` is wrong).

   **After generation**, `amlt template` prints every unresolved
   `<placeholder>` with the command that resolves it — follow those hints
   rather than guessing. Most placeholders can wait for a submit-time
   error to flag them; **`<target-name>`** is the one exception that
   **must** be resolved first: schema validation rejects it, so it's
   blocking. `-t <name>` fills it automatically. *Local* has none; *AML*
   needs only this.

   **Identity / auth is not a value you hunt for.** Do **not** search
   targets (`target list -t …`, `target info`) for an identity or
   invent one:

   - **Manifold** — the User-Assigned Managed Identity is
     **auto-detected from the bound workspace**; the scaffold has no
     identity placeholder, so there is nothing to fill. Only if
     `amlt run` reports the identity is *ambiguous* (multiple
     candidates) add `_AZUREML_SINGULARITY_JOB_UAI: <client-id>` under
     the job's `submit_args.env`, choosing from the list `amlt run`
     printed — never from elsewhere.
   - **Volcano** — set `AMLT_VOLCANO_SERVICE_ACCOUNT` to a
     workload-identity ServiceAccount in the target namespace; the
     scaffold's env comment has the `kubectl` lookup. Don't invent it.
   - **AML / Local** — none.

   Treat the user as having "named the target" only per
   never-invent-values — free-form labels (*"the V100 cluster"*) do
   not count.

   **AML only:** nothing beyond `<target-name>` — the workspace is
   already part of the compute target's registration, so there's no
   separate workspace-binding, queue, or PVC step.

   **Manifold only:** the config carries its own workspace via
   `target.workspace_name` (the `amlt template` scaffold includes it as a
   `<workspace-name>` placeholder). Fill it with the workspace the user
   named; discover the options with `amlt --json-tables workspace list
   manifold`. If that workspace isn't registered yet, run `amlt workspace
   add -y <workspace>` first (resource group and subscription are
   auto-discovered from the name). Prefer setting `workspace_name` in the
   config over `amlt workspace set-default` — keep the workspace explicit
   in the YAML rather than relying on hidden per-target default state.

   **Volcano only:** also resolve `target.queue` and
   `storage.output.pvc_name` — see *Volcano: resolve queue and PVC*
   below.

   **Local only:** no target, workspace, identity, queue, or PVC.
   Output goes to a local dir (`-o <dir>`), not blob storage; GPUs need
   `--devices all`. amlt authenticates Docker to ACR itself — never tell
   the user to run `az acr login`.

   **Experiment name.** `<exp-name>` is the positional arg to `amlt run`
   (not a YAML placeholder) — the label you'll search for in `amlt
   status` / `results`. Use the user's name if given; otherwise
   **propose** a short, descriptive, filesystem-safe one (e.g.
   `volcano-gpu-smoketest`). Don't ask a separate question and don't fall
   back to amlt's random default — show the proposed name in the
   submission summary below, confirmed by the same `yes`.

   **3b. Confirm before submitting.** Print a submission summary and
   wait for the user to type `yes`. The summary catches wrong project /
   target / identity — silent at submit time, expensive to undo.

   ```bash
   amlt project   # active project name, storage account, container, subscription
   ```

   Print these fields, reading the rest from the resolved config:

   - **Experiment**: `<exp-name>` (proposed, unless the user named it) — `<goal>`
   - **Project**: name / storage account / container / subscription
   - **Target**: `service` / `name` (AML: also the workspace and compute
     cluster; Manifold: also `workspace_name`; Volcano: also
     `queue` and `storage.output.pvc_name`; Local: no `name` — runs in
     Docker on this machine)
   - **Identity / auth**: Manifold's `_AZUREML_SINGULARITY_JOB_UAI` is
     auto-detected from the workspace and is normally **absent**
     from the config — that is expected, **not** a risk to flag. Only
     show it if `amlt run` reported an ambiguous identity and you set
     one explicitly. Volcano's `AMLT_VOLCANO_SERVICE_ACCOUNT` should name
     a workload-identity ServiceAccount from the target namespace (see
     the scaffold's env comment for the `kubectl` lookup). AML and Local
     carry no identity field — skip this line.
   - **Code**: `code.local_dir` resolved to an absolute path
   - **Jobs**: count and, per job, `name` + `sku`

   If any field is still a `<placeholder>` or empty, do not show the
   prompt — go back to 3c.

4. **Submit.**

   ```bash
   amlt run <config.yaml> <exp-name> -d "<goal>"
   ```

5. **If submission fails**, read the error message and act. This table is
   for **submission-time** errors only (errors before the job starts
   running). Runtime failures — OOM, image pull at runtime, code
   tracebacks — belong to [troubleshoot.md](troubleshoot.md).

   | Error text contains | Diagnosis | Fix |
   |---|---|---|
   | `Unknown field`, `Expected ... got ...`, `Invalid value` | Schema error in config | `amlt schema show config <field>`, edit YAML, resubmit. |
   | `Target not found`, `No such target` | Target name wrong or not registered | `amlt --json-tables target list <service>`; either correct `target.name` or run [setup.md](setup.md) — *Checkout or Create the project*. |
   | `Workspace not set`, `default workspace` | Manifold target has no workspace | Set `target.workspace_name` in the config (discover with `amlt --json-tables workspace list manifold`), resubmit. |
   | `No project`, `project not found` | Project not checked out on this machine | [setup.md](setup.md) — *Checkout or Create the project* (`amlt project checkout`). |
   | `TooManyRequests`, `Queued resource count ... maximum` | Cluster-wide queue cap — not your config | Cancel your queued jobs to free quota, or switch to a peer target in the same RG ([storage-and-identity.md](storage-and-identity.md) §5). |
   | `sla_tier` invalid / not allowed | Tier not offered by this target | Remove `sla_tier` (platform default) or `amlt schema show config jobs.sla_tier` ([storage-and-identity.md](storage-and-identity.md) §4). |
   | `PermissionDenied`, `AuthorizationFailed` reading ckpt / writing results | Project bound to an account the job's identity can't reach (NOT a YAML bug) | [storage-and-identity.md](storage-and-identity.md) §1 — rebind project / fix UAI authorization. |
   | `FileNotFound` for a path you "uploaded" | Either a stray `is_output` datastore, or blobfuse never flushed a large file | [storage-and-identity.md](storage-and-identity.md) §2 & §6. |
   | `vulnerability`, `CVE`, `FedRAMP`, `scan` blocked submission | Image failed the security scan (Manifold enforces it; Volcano doesn't) | Use a patched/clean image. **Do not** disable the scan to push it through (`never-bypass-a-security-control`). |
   | `Cannot connect to the Docker daemon`, `docker: command not found` | Docker not installed or not running (Local backend) | Start Docker and verify with `docker info`, then resubmit — or pick a cluster backend. |
   | Image pull / quota / OOM at runtime | Runtime failure, not submission | [troubleshoot.md](troubleshoot.md). |

   For any other error, run `amlt run --json-help` and re-read the config — do not
   retry the same command unchanged.

If you got through step 4 without an error, go to *Monitor*. The
rest of this document is the fallback for when the happy path doesn't
work or the user wants more control.

### Volcano: resolve queue and PVC

The template's placeholder hints print the `kubectl` commands for
`storage.output.pvc_name` (and the namespace). Two things the hints
can't tell you:

- `target.queue` equals the namespace on the clusters we use
  (`NS=$(kubectl config view --minify -o jsonpath='{..namespace}')`).
  The schema has **no** `target.namespace` field — don't add one.
- If `NS` is empty or several PVCs match, **ask** — never assume
  `default` or leave an empty `queue`. Pick a Bound, RWX PVC.

## Guardrails

- **verify-command-details-with-json-help** — Treat `amlt <cmd> --json-help` (structured JSON) as the source of truth for a command's flags, options, and subcommands. Prefer `--json-help` over `--help`. Don't guess or hard-code them — if a detail isn't in this skill, look it up with `--json-help` before acting.
- **never-invent-values** — Read target / workspace / project from `amlt --json-tables target list` and `amlt project`. When you need to *extract* a value (target name, SKU, status, results path), always pass `--json-tables` immediately after `amlt` and parse the JSON — never scrape the human-readable table. Ask the user only when reading fails. A string in the user prompt is **not** a target name unless they explicitly identified it as one (*"target: X"*, *"submit to X"*); free-form labels (*"the V100 cluster"*, *"3-GPU box"*) are descriptions — verify against `amlt --json-tables target list <service>`. (Exception: a single cluster codename — e.g. *"run on bonete"* — may be passed straight to `amlt template -t <codename>`. amlt resolves it to a backend or errors, so this is deferring to amlt, not inventing a value.)
- **use-only-the-supplied-workspace** — When the user names a workspace, use exactly that one. Never substitute, fall back to, or pivot to a different workspace, target, or resource group if the named one is missing or inaccessible, and never guess its resource group or subscription. If the supplied workspace can't be found or accessed, stop and report that — ask the user rather than picking another.
- **distinguish-profile-from-run-config** — Distinguish a team/project profile (subscription, workspace, cluster, queue) from an `amlt run` config (jobs, environment, code). Do not pass the former to `amlt run`.
- **never-tail-follow-logs** — Never run `amlt logs tail -f` — it blocks indefinitely. Use `amlt logs view -n <lines>`.
- **do-not-pipe-amlt-output** — Do not pipe `amlt` output through `head`, `tail`, or `tee`; its TTY rendering breaks. Redirect to a file instead.
- **confirm-destructive-commands** — Never run `amlt cancel` or `amlt remove` without explicit user confirmation, and never pass `--yes` on the agent's behalf. (See *Cancel*.)
- **use-only-backend-commands-from-amlt-show** — For backend-level debugging, run only the commands that `amlt show <exp> :<job>` prints — do not improvise `kubectl` or `az ml` commands.
- **confirm-first-time-team-setup** — `amlt project create`, `amlt workspace add`, and identity setup create or modify shared team resources — echo the exact command and wait for the user's "yes" before running. Per-machine checkout you may run with one confirmation.
- **never-overwrite-existing-configs** — Never overwrite an existing `amlt run` config without explicit user confirmation. Extend it or copy to a new path.
- **discover-configs-only-in-cwd** — Config discovery is cwd-only — you may not `cd` to widen it, and you may not scrape other directories for values. The cwd is the directory the caller (or parent skill) gave you; `cd` there once at the start, then treat it as fixed. Never recursively scan `$HOME`, parent dirs, sibling dirs, repo-root, or shared-harness dirs — no `find ~`, no `find /home/<user>`, no `grep -r`, no `ls ../` — to look for an `amlt run` config, a `.amltconfig`, a UAI / managed-identity value, a subscription, a workspace, or any other amlt setting. This applies to cluster sources too: never mine running pods, other jobs, or `kubectl` / `az` output for an identity or other value. Never `cd` elsewhere to make a foreign config become "cwd-local." If a value isn't in cwd or in the user's prompt, **ask the user** (per [setup.md](setup.md)); if they name an existing checkout to reuse, `export AMLT_PROJECT_DIR=<their path>` and re-run `amlt project`. If cwd has no `amlt run` config and the user did not name a path, generate a fresh one in cwd with `amlt template`.
- **yield-after-submit** — After `amlt run` returns experiment names, stop and report them — do not poll status, tail logs, or pre-emptively re-submit in the same turn. **Exception:** if the user explicitly asked you to wait for the job to finish or succeed, block until it reaches a terminal state using the *Monitor* approach, then report the outcome. The `amlt watch` patterns in *Monitor* are otherwise for follow-up turns. Likewise, if a detection probe (step 1, or in [setup.md](setup.md)) fails, emit the filled-in commands and wait for confirmation before running them; do not persist environment changes (`~/.bashrc`, `.envrc`) without asking.
- **do-not-fall-back-to-local-execution** — When detection suggests amlt cannot reach the cluster (no project, no target, auth failed), stop and report — do not run the user's training script with `python ...`, `bash ...`, or a raw `docker run ...` as a fallback. Running scripts *outside* amlt bypasses snapshotting, identity, and quota controls, and corrupts state files (`.amltconfig`, results layout) that downstream amlt commands depend on. This does **not** forbid amlt's Local backend: `amlt run -t local` runs the job in Docker *through amlt* and is a valid choice when the user wants a local/Docker run — the prohibition is on going around amlt, not on the `local` backend itself.
- **treat-nonzero-exit-as-failure** — A non-zero exit code means the command failed. Check the exit status of every amlt command. A non-zero exit (permission denied, config error, quota, missing TTY, etc.) means the action did NOT happen — the job was not submitted, the workspace was not added, and so on. Never report success, print a "✅ done" summary, or move on until the command exits 0 (confirm with `amlt status` where appropriate). Surface the actual error instead of declaring success.
- **never-bypass-a-security-control** — When the cluster blocks submission for a security reason (a failed CVE / FedRAMP vulnerability scan, a policy check, a signature requirement), do not try to get around it. Never recommend, set, or pass any flag or environment variable that weakens or disables the check to push the blocked image or job through — that's the user's call, not yours, so never present a bypass as the "recommended" option. Report the block and what failed, and offer the safe fix (e.g. a patched/clean image). Apply a documented override only if the user, unprompted, explicitly tells you to — and even then, echo the exact command and let them run it.
- **generate-configs-with-amlt-template** — The **only** way to generate an `amlt run` config is `amlt template -t <service-or-target> -f <path> -y`; no hand-written files allowed. After generating, limit your edits to filling in values: the `<placeholder>` markers and any field an inline comment marks `REQUIRED` (e.g. `code.local_dir`, Volcano's `queue`/`pvc_name`); don't restructure the scaffold, swap the image, or change the `command:` form. When you need to change or add a field, consult `amlt schema show config <field>` (e.g. `amlt schema show config jobs.sku`) for its type, valid values, enums, and structure before editing — don't guess; the output is compact JSON Schema meant for you to parse. Never hand-type, paste-from-memory, or `cat >`/heredoc a config — if you're typing `environment:`, `image:`, or `jobs:` into a file, stop and run `amlt template`. Hand-written configs miss required scaffold (e.g. Volcano's `storage.output.pvc_name`), skip the schema modeline, drop the sanctioned `msrcommonacr` image for a public one that fails the security scan, and drift from the schema.
- **always-confirm-the-backend** — AML, Manifold, Volcano, and Local templates emit very different YAMLs. If the user did not name a backend (in the prompt or by naming a target), stop and ask — even if `amlt target list` shows one option. A cwd config does not count as "user named the backend" unless it was generated by `amlt template` (look for the `# yaml-language-server: $schema=…amlt-config.schema.json` modeline and the backend-specific scaffold). A bare hand-written `service: volcano` line is not authoritative. (Naming a cluster codename *does* count as naming the backend — let `amlt template -t <codename>` resolve it rather than asking.)
- **separate-setup-asks-from-submit-asks** — When first-time setup is needed, ask only for the two values `amlt project checkout` needs — project name and storage account (the container defaults; don't ask). Do not bundle submit-time concerns (backend, target, kubectl context, PVC, image, SKU) into the same ask. A 4-item upfront questionnaire is a sign you're skipping ahead.


## Submit

The *Quick start* covers the happy path. This section is for when you
need more than the basic template — sweeps, hyperdrive, multi-job,
multi-node — or when you hit a schema error after submitting.

```bash
amlt template -t aml      -s   -f sweep.yaml -y   # random/grid search block
amlt template -t manifold -hd  -f hd.yaml    -y   # hyperdrive (Bayesian) block
amlt template -t volcano  -d   -f multi.yaml -y   # adds mpi + process_count_per_node
amlt template -t volcano  -n 3 -f multi.yaml -y   # 3 extra job entries
amlt template -t local    -f local.yaml -y        # run in Docker on this machine
```

Local runs go through `amlt run` like any other backend, but execute in a
Docker container on the current machine — add `-t local --devices all` to
run an existing config locally on all GPUs, and `-o <dir>` to choose the
output directory (the experiment name defaults to `local` when you omit
`<exp-name>` and have no Azure-backed project; pass a name to override it):

```bash
amlt run config.yaml :job1 -t local --devices all -o ./out
```

Inspect the schema only on a schema error:

```bash
amlt schema show config target.service   # allowed backends
amlt schema show config jobs.sku          # SKU field
```

## Monitor

**Local backend:** `amlt run -t local` executes the job in the foreground
and streams container output directly to your terminal, so there is no
background job to poll — the `amlt watch` / `amlt status` patterns below
apply to cluster backends (AML, Manifold, Volcano). For a local run, read
the streamed output and the files written under the output directory
(`-o <dir>`).

### Wait for jobs to finish (default — use this)

`amlt watch` is the right tool whenever the goal is "block until these
jobs reach a terminal state." It polls in the background, exits with a
meaningful code, and can wake early on a log-line match. Prefer it over
`amlt status --loop-interval` and over any `sleep && amlt status` loop.

```bash
amlt watch <exp>                                          # block until all jobs finish
amlt watch <exp> :<job1> :<job2>                          # subset of jobs
STATE_FILE="${TMPDIR:-/tmp}/amlt-watch-<exp>.json"        # Windows: %TEMP%\amlt-watch-<exp>.json
amlt watch <exp> --json --state-file "$STATE_FILE"        # JSONL events, resumable
amlt watch <exp> --grep 'OOM|Traceback' --exit-on-grep --state-file "$STATE_FILE"
```

When `amlt watch` exits non-zero, react instead of re-polling blindly.
On a grep-match exit, inspect the match, then re-run the same
`amlt watch ... --state-file ...` command (same `--grep`, same
`--state-file`) to resume from where it left off. On a job-failure exit,
diagnose the runtime failure with [troubleshoot.md](troubleshoot.md),
then rerun or resume the affected jobs per [recover.md](recover.md).

Do not run `amlt watch` without `--json` inside a non-interactive shell —
its TTY rendering breaks when redirected. Use `--json` for any piped or
logged invocation.

### One-shot status

Use `amlt status` only for a single point-in-time check (e.g. answering
"how is `<exp>` doing right now?"). Do not loop it from an agent — use
`amlt watch` instead.

```bash
amlt status <exp> [:<job>]                                # one-shot snapshot
amlt status -n 3 <exp>                                    # 3 most recent jobs
```

### Logs

```bash
amlt logs view -n 200 <exp> :<job>                        # last N lines (never tail -f)
amlt logs view -F user_logs/std_log.txt <exp> :<job>      # a specific log file; see `amlt logs --json-help` for -s/-F filters
```

### Results

```bash
amlt results list <exp> :<job>                            # check sizes first
amlt results download <exp> :<job>                        # download outputs; see `amlt results --json-help` for -s/-I filters
```

## Cancel

Cancel is destructive — in-progress work is lost. Per
confirm-destructive-commands, never call `amlt cancel` without
explicit user confirmation.

```bash
# 1. Identify scope and show what will die.
amlt status <exp>                                         # whole experiment
amlt status <exp> :<job>                                  # single job

# 2. Wait for the user's "yes".

# 3. Cancel. Let amlt's interactive y/N prompt run — do not bypass it
#    with --yes from an agent loop.
amlt cancel <exp>                                         # whole experiment
amlt cancel <exp> :<job>                                  # one job
amlt cancel <exp> -s queued                               # only queued jobs

# 4. Verify cancellation reached the backend.
STATE_FILE="${TMPDIR:-/tmp}/amlt-cancel-<exp>.json"       # Windows: %TEMP%\amlt-cancel-<exp>.json
amlt watch <exp> --json --state-file "$STATE_FILE"
# Exits 0 once all selected jobs are terminal.
```

If `amlt cancel` reports "no cancellable jobs," they are already
terminal — nothing to do.
