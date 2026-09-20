# `amlt agent`

Manage agent integration helpers for the amlt CLI.

**Subcommands:** `skill`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt agent skill`

Manage amlt CLI skill files for supported agents.

**Subcommands:** `clear`, `diff`, `edit`, `install`, `list`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

### `amlt agent skill clear`

Remove an installed amlt-cli agent skill (Copilot clear also disables auto-install).

**Parameters:**

  - `AGENT_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

### `amlt agent skill diff`

Show differences between installed SKILL.md and the bundled version.

**Parameters:**

  - `AGENT_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

### `amlt agent skill edit`

Open the installed SKILL.md in $EDITOR.

**Parameters:**

  - `AGENT_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

### `amlt agent skill install`

Install the amlt-cli skill for Claude or Copilot.

**Parameters:**

  - `AGENT_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

### `amlt agent skill list`

List installed skill files for an agent (absolute paths).

**Parameters:**

  - `AGENT_NAME` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.
