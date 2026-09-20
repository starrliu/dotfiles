## First-time setup (only when a project isn't ready)

You're here because there's no active amlt project for this directory.
The detection probes already ran — don't repeat them; work through
*Checkout or Create the project* below.

**Local (Docker) skips the amlt project, storage, workspace, and
target** — it runs on the current machine through Docker. Then return to
[workflow.md](workflow.md) — *Generate a minimal config*. Everything
below is for the cluster backends.

### Checkout or Create the project

`checkout`/`create` take the **project name** plus, if no storage
account is already set, the **storage account** — the coordinates that
locate the project, not new associations. The container defaults, so
don't ask for it. With a project already active these carry over (from
the `.amltconfig` in the resolved directory), so the name alone is
enough.

Both write a `.amltconfig` (the active-project pointer) into
`AMLT_PROJECT_DIR` (or the cwd if unset). Pick a dedicated directory so
you don't overwrite or inherit another `.amltconfig`. Per
discover-configs-only-in-cwd, ask the user for whatever isn't already
set — don't scrape sibling checkouts. To reuse an existing checkout,
`export AMLT_PROJECT_DIR=<that path>`, re-run `amlt project` to confirm,
and skip the rest of this section.

1. **Pick a writable directory on a non-root data disk** (fall back to
   `$HOME` if there is no separate data disk). On Linux you can use `df`
   to find candidates. Confirm the path with the user before exporting.

2. **Export `AMLT_PROJECT_DIR`** — once set, every subsequent `amlt`
   command uses that location without `cd`:

   ```bash
   export AMLT_PROJECT_DIR="<chosen-path>/<project>-amlt"
   mkdir -p "$AMLT_PROJECT_DIR"
   ```

   A bare `export` resets in the next shell. If the project is one the
   user will reuse, offer to persist it (`~/.bashrc`, `.envrc`).

3. **Ask for the project values one at a time.** Always ask the project
   name. Ask for the storage account only if no project is currently
   active (when one is, it carries over). Don't ask for the container —
   it defaults. Ask in order, wait for each answer:

   1. *"What's the amlt project name?"*
   2. *"What's the Azure storage account?"* (skip if already set)

   Per separate-setup-asks-from-submit-asks, do not bundle submit-time
   concerns (target, image, SKU, kubectl context) into this ask — those
   come later.

4. **Check out the project — this doubles as an existence probe.** Echo
   the command, then run it:

   ```bash
   # Positional args — no -s/-c flags. Container defaults; don't pass it.
   amlt project checkout <project> <storage> -d "$AMLT_PROJECT_DIR"
   ```

   - **Succeeds** → the project existed and is now checked out. Go to
     step 5.
   - **Reports `... does not exist`** → don't auto-create (a miss can
     also mean a typo or wrong storage account). Tell the user it isn't
     in `<storage>` and confirm they want a new one. Only after "yes",
     create it — this modifies shared team resources, so echo the exact
     command first (`confirm-first-time-team-setup`). `create` also
     checks out, so no second checkout is needed:

     ```bash
     # Positional args — no -s/-c flags. Container defaults; don't pass it.
     # create also checks out.
     amlt project create <project> <storage-account> -d "$AMLT_PROJECT_DIR"

     # Register the AzureML workspace (only for Manifold/AML).
     # Resource group and subscription are auto-discovered.
     amlt workspace add -y <workspace>
     ```

5. **Confirm the target is visible.** For Manifold, the workspace goes in
   the run config (`target.workspace_name`), not a per-target default:

   ```bash
   amlt --json-tables target list <service>   # service: aml | manifold | volcano | batch
   amlt --json-tables target info <service>
   amlt --json-tables workspace list manifold                           # Manifold: discover workspace names
   ```

   The workspace's clusters were already imported as targets by
   `amlt workspace add -y` above — don't run `amlt workspace sync` here
   (it only re-refreshes targets later, after the backend changes).

   For **AML**, `amlt target list aml` should show the compute cluster
   registered above; its workspace is already bound by the target. For
   **Manifold**, set `target.workspace_name` in the run config (the
   `amlt template` scaffold includes a `<workspace-name>` placeholder) —
   prefer that over `amlt workspace set-default`, which hides the
   workspace in per-target default state.
