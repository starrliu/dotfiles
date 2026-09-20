# `amlt target`

Add, remove, list, and sync compute targets.

**Subcommands:** `add`, `add-defaults`, `clear`, `info`, `list`, `list-defaults`, `remove`, `sync`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt target add`

Add a specified target to your project's list of targets.

  Targets can be used in the 'name' field in the YAML or specified with "amlt run --target <target> ...".
  The target will also be shown in "amlt target info".

  Example: Add all compute targets in an aml workspace to the amlt project. Their names will be the corrresponding
  cluster names:

  ``$ amlt target add --subscription  ... --resource-group ... --workspace-name ...``

  Example: Add a specific compute target from an aml workspace to the amlt project:

  ``$ amlt target add target_name --subscription  ... --resource-group ... --workspace-name ... --cluster ...``

**Parameters:**

  - `TARGET_NAME`
  - `--sync`: When providing a workspace, also remove targets that are not present in the workspace anymore.
  - `--service` `SERVICE`: Service of the target. (default: `Sentinel.UNSET`)
  - `--subscription` `SUB_ID_OR_NAME`: Subscription name or subscription id. (default: `Sentinel.UNSET`)
  - `--resource-group` `NAME`: AML resource group. (default: `Sentinel.UNSET`)
  - `--workspace-name` `NAME`: AML workspace name. (default: `Sentinel.UNSET`)
  - `--cluster` `NAME`: Cluster for the target. (default: `Sentinel.UNSET`)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt target add-defaults`

Add defaults targets from AMLT.

**Parameters:**

  - `DEFAULT_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt target clear`

Remove all targets currently registered from this project.

**Parameters:**

  - `-y`, `--yes`: Do not ask for confirmation.
  - `-f`, `--force`: Force removal.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt target info`

Show GPU availability of a virtual cluster. Shortcut: ``amlt ti``

  If you frequently use the same service, you can set AMLT_DEFAULT_SERVICE to avoid typing it.
  Default service is 'manifold'.

  Use ``-t pool@account`` to disambiguate batch pools with the same name across accounts.
  Use ``-t @account`` to filter to a specific batch account (glob patterns supported,
  e.g. ``-t @ai4s*``).

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `-t`, `--target-name` `TARGET_NAME`: Target name. Use @account (glob patterns supported) to filter batch pools by account. (default: `Sentinel.UNSET`)
  - `-c` `YAML_FILE`: Config file for loading target options.
  - `-l`, `--length` `FLOAT`: Window length (in hours) over which to show the clusters' predicted co2 emissions. Only on AMLK8S and AML. (default: `1`)
  - `SERVICE`
  - `-v`, `--verbose`: Shows instance type series details
  - `-a`, `--all-subscriptions`: Query all subscriptions instead of only previously seen ones.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt target list`

List target names and their meta-info. Shortcut: ``amlt tl``.

  If you frequently use the same service, you can set AMLT_DEFAULT_SERVICE to avoid typing it.
  Default service is 'manifold'.

  Use ``-t pool@account`` to disambiguate batch pools with the same name across accounts.
  Use ``-t @account`` to filter the list to a specific batch account (glob patterns supported,
  e.g. ``-t @ai4s*``).

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `SERVICE`
  - `-t`, `--target-name` `TARGET`: Print detailed info on given target. Use @account (glob patterns supported) to filter batch pools by account. (default: `Sentinel.UNSET`)
  - `-v`, `--verbose`: Shows additional details.
  - `--nu`, `--no-update`: Only lists locally cached targets
  - `-a`, `--all-subscriptions`: Query all subscriptions instead of only previously seen ones.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt target list-defaults`

List defaults target collections from AMLT.

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt target remove`

Remove the specified target from your local list of targets.

  After removal, the target name cannot be used in config files, ``amlt run``, and
  ``amlt target info`` anymore.

**Parameters:**

  - `TARGET_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt target sync`

Sync project targets with AML clusters found in the manually added workspaces.

  This will add targets in the workspace(s) and remove targets that are not found in the workspaces anymore.
  You can specify the workspaces to sync, or sync all manually added workspaces by omitting the workspace names.

**Parameters:**

  - `WORKSPACES` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
