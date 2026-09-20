---
name: amlt-cli
description: >-
  Authoritative reference for the amlt (Amulet) CLI for managing ML
  experiments on AzureML, Singularity, Volcano, and Azure Batch.
  Use when the user needs to submit jobs, check status, view logs,
  download results, configure targets, debug experiments,
  or write/edit amlt YAML config files — even
  if they just say "run this", "check my job", or "get the logs".
---

# amlt CLI Skill

amlt is a frontend for managing ML experiments on AzureML, Singularity/Manifold, Volcano, and Azure Batch. It only manages jobs created through amlt itself.

## Guardrails

Always follow these rules when constructing amlt commands:

- **Look up exact option names** before running any command. Use `amlt <cmd> --json-help` for structured JSON describing all options, or read the command's reference file (linked in Commands below). Do NOT guess or infer option names from other CLIs. Examples of amlt-specific names:
  - `--most-recent` not `--last`
  - `--loop-interval` not `--interval`
  - `--filter-status` not `--status` (for `amlt status`)
- **Batch jobs in one call** — most commands accept `:<job1> :<job2>`, `:job*` (glob), or `@tag`.
- **Use `amlt --json-tables <cmd>`** (or `AMLT_JSON_TABLES=1`) for machine-readable JSON output. Run `amlt schema show output <cmd>` to discover the exact field names, types, and enums before writing parsing code (e.g. `amlt schema show output status`).
- **Always use `--json-tables` when you read a command's output to extract a value** (target name, SKU, status, results path) — e.g. `amlt --json-tables target list`, `amlt --json-tables status <exp>`. Parse JSON, never scrape the human-readable table. Use the bare form only when displaying output for the user to read.
- **Use `amlt <cmd> --json-help`** to get structured JSON describing a command's options, arguments, and subcommands (recursive for groups).
- **Never use `amlt logs tail -f`** — it blocks indefinitely. Use `amlt logs view -n <lines>` instead.
- **Check sizes before viewing** — `amlt results view` prints entire files. Use `amlt results list` first, then pipe through `head`.
- **Generate configs with `amlt template`, never hand-write them** — the only sanctioned way to create an `amlt run` config is `amlt template -t <target-or-codename> -f <path> -y`. After generating, fill in only the `<placeholder>` values and `REQUIRED` fields; don't restructure the scaffold. When you need to change or add a field, consult `amlt schema show config <field>` (e.g. `amlt schema show config jobs.sku`) for its type, valid values, enums, and structure — don't guess. The output is compact JSON Schema meant for you to parse.
- **Never invent or copy values** — read target / identity / PVC / subscription from the lookup commands amlt prints, from `amlt --json-tables target list`, or from `amlt schema show config`. Never copy values from other directories, past runs, or sibling workspaces, and never scrape unrelated dirs (`find`/`grep -r` outside the current working directory). If a value can't be discovered, stop and ask.
- **A non-zero exit code means the command failed.** Always check the exit status of every amlt command. A non-zero exit (permission denied, config error, quota, missing TTY, etc.) means the action did NOT happen — the job was not submitted, the workspace was not added, etc. Never report success, print a "✅ done" summary, or move on until the command exits 0 (confirm with `amlt status` where appropriate). Read and surface the actual error instead of declaring success.
- **Only use the workspace the user supplied.** If the user names a workspace, use exactly that one. Do NOT substitute, fall back to, or pivot to a different workspace, target, or resource group if the named one is missing or inaccessible — and do NOT guess its resource group/subscription. If the supplied workspace can't be found or accessed, stop and report that; ask the user rather than picking another.

# Workflows

Follow the workflow that matches the user's goal. Each workflow is a step-by-step procedure with decision points.

## Investigate a job

Goal: figure out why a job failed, is stuck, or behaves unexpectedly.

1. `amlt status <exp> [:<job>]` — get the current state.
2. If the job is **Running** but you expected results:
   a. `amlt logs view -n 100 <exp> :<job>` — check recent output.
   b. If logs are empty or say "Waiting for image pull", wait and retry.
3. If the job is **Failed**:
   a. `amlt show <exp> :<job>` — read the backend info section.
      It contains backend-specific commands (kubectl, az ml, az batch)
      you can run to get the real error.
   b. `amlt logs view -n 200 <exp> :<job>` — look for the traceback.
   c. Branch on failure cause:
      - **Image pull error** → fix the image name/tag in the YAML config.
      - **OOM / eviction** → increase `sku` (bigger VM) or reduce batch size.
      - **Quota exceeded** → try a different target or wait for capacity.
      - **Code error (Python traceback)** → fix the code, then `amlt rerun`.
      - **Unknown** → use the backend commands from `amlt show` output.
4. If the job is **Queued** for a long time:
   a. `amlt show <exp> :<job>` — check the target and SKU.
   b. The cluster may be full. Consider a different target or lower priority.

## Submit a job

Goal: submit a new experiment from a YAML config file.

1. **Use an existing config if there is one:**
   a. Look for an `amlt run` config **in the current directory** (cwd only — do
      not `cd` elsewhere or scan sibling/parent dirs). If the user pointed at a
      specific file, use that path directly.
   b. If a suitable config exists, read it, confirm its `target.service` matches
      the backend you intend, and skip to step 3.
   c. Only if cwd has no config (and the user named no path) do you create one —
      go to step 2.

2. **Generate a config with `amlt template` — never hand-write one:**
   a. `amlt template -t <target-or-codename> -f <config.yaml> -y` — scaffolds a
      backend-correct config. Read the printed `Resolved … backend` line to
      confirm which backend the target/codename mapped to.
   b. If you don't know the target yet, `amlt --json-tables target list` first,
      then pass its name to `-t`.
   c. Fill in only the `<placeholder>` values and any field an inline comment
      marks `REQUIRED` (e.g. `code.local_dir`, Volcano's `queue`/`pvc_name`).
      Each placeholder's lookup command is printed under "Unresolved
      placeholders" — run it to discover the value. Never invent values or copy
      them from other directories, past runs, or sibling workspaces; if a value
      can't be discovered, stop and ask. To change or add any other field,
      consult `amlt schema show config <field>` (e.g.
      `amlt schema show config jobs.sku`) for its type, valid values, and
      structure before editing — don't guess. The output is compact JSON Schema.
   d. ⚠️ amlt uses `$`-substitution (Python `string.Template`).
      To use literal `$` in commands, escape as `$$`.

3. **Submit:**
   ```
   amlt run <config.yaml> <exp-name> [-t <target>] [--description "goal of experiment"]
   ```
   - Use a mnemonic experiment name so the purpose is obvious.
   - Pass `--description` summarizing the goal and code changes.

4. **Verify the job was accepted** (jobs can be silently rejected):
   ```
   sleep 3m && amlt status <exp-name>
   ```
   - If status is Failed immediately → check `amlt show` and `amlt logs view`.
   - If status is Queued → the job was accepted, wait for scheduling.

## Debug a running job

Goal: interact with or diagnose a live running job.

1. `amlt show <exp> :<job>` — get backend-specific identifiers and commands.
2. Branch on backend type (shown in `amlt show` output):
   - **AML Compute / Singularity:**
     - Use the `az ml job show` / `az ml job stream` commands from the output.
     - `amlt ssh <exp> :<job>` — SSH into the running container.
   - **Volcano (Kubernetes):**
     - Use the `kubectl describe pod` / `kubectl logs` commands from the output.
     - `amlt ssh <exp> :<job>` — SSH if the pod supports it.
   - **Azure Batch:**
     - Use the `az batch task show` commands from the output.
     - If the pool isn't scaling → see `references/troubleshooting.md`.
3. `amlt logs tail <exp> :<job>` — stream live output.
   ⚠️ This blocks indefinitely. Only use in an async/background shell.

## Download and analyze results

Goal: retrieve and inspect job outputs.

1. `amlt results list <exp> :<job>` — see available files and sizes.
2. If files are **small** (< 1 MB):
   - `amlt results view <exp> :<job> -f <filename>` — print to stdout.
3. If files are **large**:
   - `amlt results download <exp> :<job>` — download to local directory.
   - Or pipe: `amlt results view <exp> :<job> -f <file> | head -n 50`
4. To share results:
   - `amlt results share <exp> :<job>` — get a shareable link.

## Set up a target

Goal: configure a new compute target.

1. `amlt workspace list` — see configured workspaces.
2. If the workspace isn't listed, `amlt workspace add <workspace> --yes` —
   add the AML workspace. The resource group and subscription are
   auto-discovered from the name via Azure Resource Graph (needs only
   `Reader`); pass `--resource-group` / `--subscription` only to
   disambiguate when the name matches more than one workspace. `--yes`
   auto-confirms importing the workspace's clusters as targets (needed for
   non-interactive runs) — so there's **no** need to run `workspace sync`
   afterward; `add` already imported them.
3. If the workspace exists but the target isn't listed:
   a. `amlt workspace sync <workspace>` — refresh targets from backend.
4. `amlt --json-tables target list` — confirm the target appears.
5. `amlt --json-tables target info -t <target>` — verify SKUs and quota.

## Chain jobs with map

Goal: run a follow-up job that consumes the outputs of a previous experiment
(e.g. pretrain → finetune → evaluate).

1. **Write a map config file** (e.g. `map.yaml`).
   - Define the follow-up job (e.g. `finetune` or `evaluate`).
   - Reference the previous job's output directory as `$$AMLT_MAP_INPUT_DIR`
     in the command string.
   - The map job writes to `$AMLT_OUTPUT_DIR` as usual (new experiment),
     or can write back to `$$AMLT_MAP_INPUT_DIR` to modify the original.

2. **Decide what to map over:**
   - All jobs in the source experiment:
     ```
     amlt map map.yaml :finetune pretrain-exp
     ```
   - Specific jobs only:
     ```
     amlt map map.yaml :finetune pretrain-exp :job-a :job-b
     amlt map map.yaml :finetune pretrain-exp :job*   # glob
     ```
   - A hyperparameter search defined in the map YAML:
     ```
     amlt map map.yaml --search pretrain-exp :best-job
     ```

3. **Naming:** The map experiment is auto-named `{map-job}-{source-exp}`.
   Override with an explicit `MAP_EXP_NAME` argument if needed.

4. **Verify** the follow-up jobs were accepted:
   ```
   sleep 3m && amlt status finetune-pretrain-exp
   ```

5. **Chain further:** You can map again on the map experiment's results
   to build multi-stage pipelines (pretrain → finetune → evaluate).

## Monitor jobs (fire-and-forget)

Goal: watch jobs until completion with notifications and optional log pattern matching.

1. **Basic watch** — wait until all jobs finish:
   ```
   amlt watch <exp> -v
   ```
2. **Watch specific jobs with fast polling:**
   ```
   amlt watch <exp> :<job1> :<job2> -i 30 -v
   ```
3. **Alert on log patterns** (e.g. OOM, CUDA errors):
   ```
   amlt watch <exp> --grep 'OOM|out of memory|CUDA error' -v
   ```
4. **Agent-friendly mode** (`--json`): emits one JSON line per event
   (types: `watching`, `poll`, `status_change`, `grep_match`, `sighup`, `completed`, `exit`).
   ```
   amlt watch <exp> --json
   ```
5. **Watch for log patterns and wake up on match** (resumable):
   ```
   amlt watch <exp> --json --grep 'OOM|CUDA error' --exit-on-grep --state-file /tmp/w.json
   ```
   After investigating, re-run the same command — `--state-file` resumes
   from where it left off (no re-matching old content).
6. **Important**: Use `mode="async"` with `detach: true` in the bash tool — do NOT use a trailing `&`.
7. **Exit codes**: 0 = all passed, 12 = any job failed/killed/expired,
   13 = grep match (with `--exit-on-grep`).
8. **SIGHUP**: On Unix, `kill -HUP <pid>` triggers an immediate status
   check and emits a `sighup` event. The PID is printed on startup
   (or in the `watching` JSON event).

## Rerun or resume jobs

Goal: run a job again (with changes) or resume a paused job.

1. Determine what's needed:
   - **Same code, same config** → `amlt rerun <exp> :<job>`
   - **Updated code** → `amlt rerun <exp> :<job>` (it picks up code changes)
   - **Different config** → edit the YAML, then `amlt run` (new experiment)
   - **Resume a paused job** → `amlt resume <exp> :<job>`
2. After rerun/resume, verify:
   ```
   sleep 2m && amlt status <exp>
   ```

## Documentation References

Detailed documentation is available in the `references/` directory.
Load these on demand for in-depth information on specific topics.

### Getting Started

- [Installing amlt, configuring credentials and storage accounts](references/setup.md)
- [End-to-end walkthrough: submitting your first job](references/tutorial.md)
- [Frequently asked questions and troubleshooting](references/faq.md)

### Configuration Basics

- [Setting up and selecting compute targets (AML, Singularity, Volcano)](references/basics-targets.md)
- [YAML config file structure and fields](references/basics-config.md)
- [Docker and base image selection for jobs](references/basics-images.md)
- [Specifying code directories and upload behavior](references/basics-code.md)
- [Job output paths, downloading results](references/basics-outputs.md)
- [Mounting and referencing datasets](references/basics-data.md)
- [Defining jobs, naming, and job parameters](references/basics-jobs.md)
- [Hyperparameter search and grid sweeps](references/basics-hyperparameters.md)

### CLI & Collaboration

- [CLI commands overview and common workflows](references/basics-cli.md)
- [Sharing experiments and working in teams](references/basics-collaborating.md)
- [Monitoring jobs: status, logs, TensorBoard](references/basics-monitoring.md)

### Advanced Topics

- [Default experiment naming and organization](references/advanced-default-experiments.md)
- [Fine-tuning jobs and building on previous results](references/advanced-finetuning.md)
- [Testing job configs locally before submission](references/advanced-testing.md)
- [Choosing between AML, Singularity, and Volcano](references/advanced-service-selection.md)
- [Multi-node distributed training setup](references/advanced-distributed.md)
- [Using premium/managed storage for large datasets](references/advanced-premium-storage.md)
- [Configuring multiple storage accounts](references/advanced-multi-storage.md)

### Configuration Reference

- [Complete YAML config file field reference](references/config-file.md)

### Miscellaneous

- [Feature support matrix across backends](references/misc-feature-support.md)
- [Weights & Biases (W&B) integration](references/misc-wandb.md)
- [Environment variables for customizing amlt behavior](references/misc-environment-variables.md)
