# `amlt cache`

Inspect and clear local caches (images, targets, SKUs).

**Subcommands:** `base-images`, `completion`, `expand-sku`, `group-policies`, `instance-types`, `shortlink`, `subscriptions`, `volcano-targets`, `vuln-scan`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt cache base-images`

Enumerates available Singularity base images.

**Parameters:**

  - `-I`, `--include` (default: `Sentinel.UNSET`)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt cache completion`

Clear/list content of job/experiment names cache.

**Subcommands:** `clear`, `list`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

### `amlt cache completion clear`

Clear the completion cache.

### `amlt cache completion list`

Prints the completion cache.

## `amlt cache expand-sku`

Enumerates instance types from a target that match a given SKU.

**Parameters:**

  - `--sla` `[Premium|Standard|Basic]` (default: `Sentinel.UNSET`)
  - `--target-and-sku`, `-t` `<TARGET_NAME MK_SKU_INFO>` (default: `Sentinel.UNSET`)
  - `--config`, `-c` `YAML_FILE`: Path to AMLT config file. (default: `Sentinel.UNSET`)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt cache group-policies`

List/clear group policies cache.

**Subcommands:** `clear`, `list`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

### `amlt cache group-policies clear`

Clears group policies cache.

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

### `amlt cache group-policies list`

List group policies.

**Parameters:**

  - `-a`, `--all`: Show groups without access.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt cache instance-types`

Enumerates instance type series and displays equivalences between instance type notation.

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `-s`, `--series`: Which series to show detailed information for (default: `Sentinel.UNSET`)
  - `-I`, `--include`: Shows instances including the specified string of characters. (default: `Sentinel.UNSET`)
  - `SERVICE`
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt cache shortlink`

Clear/list content of shortlinks cache.

**Subcommands:** `clear`, `list`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

### `amlt cache shortlink clear`

Clears short url mapping cache.

### `amlt cache shortlink list`

Lists short url mapping cache.

## `amlt cache subscriptions`

List azure subscriptions user has access to.

**Parameters:**

  - `-u`, `--update`: Updates cache
  - `-n`, `--by-name`: Sorts subscriptions by name
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt cache volcano-targets`

Manipulate volcano targets cache.

**Subcommands:** `clear`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

### `amlt cache volcano-targets clear`

Clears volcano targets cache.

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt cache vuln-scan`

Manipulate vulnerability scan cache.

**Subcommands:** `clear`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

### `amlt cache vuln-scan clear`

Clears vulnerability scan cache.

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.
