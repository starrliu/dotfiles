# `amlt workspace`

Add, list, and sync AML/Singularity workspaces and their targets.

**Subcommands:** `add`, `clear`, `list`, `remove`, `set-default`, `set-project-default`, `sync`, `unset-default`, `unset-project-default`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt workspace add`

Specific to AML+Singularity: add a workspace to your project's list of workspaces.

  When ``--resource-group`` / ``--subscription`` are omitted, the workspace is
  located by name via Azure Resource Graph (needs only ``Reader`` on its scope).

**Parameters:**

  - `WORKSPACE_NAME` **(required)**
  - `--resource-group` `NAME`: Resource group of the workspace. Auto-discovered by name via Azure Resource Graph when omitted.
  - `--subscription` `SUB_ID_OR_NAME`: Subscription name or subscription id. Auto-discovered by name via Azure Resource Graph when omitted.
  - `-y`, `--yes`: Answer 'yes' to all interactive questions.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt workspace clear`

Remove references to all manually added workspaces from the project.

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt workspace list`

Singularity specific: list workspace names. Shortcut: ``amlt wl``.

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `SERVICE`
  - `--nu`, `--no-update`: Only lists locally cached workspaces
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt workspace remove`

Singularity specific: remove the specified workspace from your local list of targets.

**Parameters:**

  - `WORKSPACE_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt workspace set-default`

Singularity specific: assign a workspace as a default workspace for a certain VC.

  To unset the default workspace, see ``amlt workspace unset-default <mytarget>``.

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `TARGET_NAME` **(required)**
  - `WORKSPACE_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt workspace set-project-default`

Singularity specific: assign a workspace as a default workspace for the current project.

  To unset the default workspace, see ``amlt workspace unset-project-default <mytarget>``.

**Parameters:**

  - `WORKSPACE_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt workspace sync`

Sync project targets with AML clusters found in the manually added workspaces.

  This will add targets in the workspace(s) and remove targets that are not found in the workspaces anymore.
  You can specify the workspaces to sync, or sync all manually added workspaces by omitting the workspace names.

**Parameters:**

  - `WORKSPACES` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt workspace unset-default`

Singularity specific: reinstate original default workspace for a certain VC.

**Parameters:**

  - `TARGET_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt workspace unset-project-default`

AML+Singularity specific: removes project-wide default workspace

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.
