# `amlt schema`

Inspect and manage JSON Schemas for Amulet.

  Use ``amlt schema show config`` to print the config-file schema or drill
  into individual fields (e.g. ``amlt schema show config target.service``).

  Use ``amlt schema show output status`` to print the JSON Schema for
  ``amlt --json-tables status`` output.

  Other subcommands help integrate the schema with editors for
  autocompletion and validation.

**Subcommands:** `add`, `path`, `show`, `update`, `uri`, `validate`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt schema add`

Add a YAML schema modeline to config files.

  Copies the Amulet JSON Schema into ``.vscode/`` in the project root
  and injects a ``yaml-language-server`` modeline into each given FILE
  so that editors with YAML language support (e.g. VS Code with the
  Red Hat YAML extension) provide autocompletion and validation.

  The modeline uses a ``file://`` URI. Re-run ``amlt schema add`` to
  update after reinstalling amlt or moving the project.

  
  Examples:
    amlt schema add jobs.yaml             # add modeline to one file
    amlt schema add a.yaml b.yaml         # add modeline to multiple files
    amlt schema add exp/train.yaml        # works for files in subdirectories
    amlt schema add                       # print the modeline (no files modified)

**Parameters:**

  - `FILES` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt schema path`

Print the filesystem path to the installed schema file.

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt schema show`

Show JSON Schemas for config files or command output.

  Subcommands::

    config [FIELD]     Config-file schema (for amlt run YAML files)
    output <COMMAND>   Output schema (for --json-tables JSON output)

  Examples::

    amlt schema show config                # full config schema
    amlt schema show config jobs.sku       # drill into a field
    amlt schema show output status         # schema for --json-tables status

**Subcommands:** `config`, `output`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

### `amlt schema show config`

Print the config-file JSON Schema, optionally filtered to a field.

  Without arguments, prints the full schema.  With a FIELD argument, prints
  only the schema definition for that field path.  Dot-separated paths walk
  into nested schemas via ``$defs``.

  Examples::

    amlt schema show config                     # full schema
    amlt schema show config jobs                # schema for the 'jobs' property
    amlt schema show config jobs.sku            # schema for jobs -> sku
    amlt schema show config jobs.submit_args.env  # env vars
    amlt schema show config target.service      # target -> service (with enum)

**Parameters:**

  - `FIELD`

### `amlt schema show output`

Print the JSON Schema for a command's ``--json-tables`` output.

  Shows the structure of the JSON array emitted by ``amlt --json-tables <command>``.
  Without arguments, lists all commands with documented output schemas.

  For commands with per-backend schemas, use slash notation (e.g. ``target-list/sing``).

  Examples::

    amlt schema show output                 # list available commands
    amlt schema show output status          # schema for --json-tables status
    amlt schema show output target-list/sing  # schema for target list (Singularity)

**Parameters:**

  - `COMMAND`

## `amlt schema update`

Update the .vscode schema with discovered targets and SKU examples.

  Reads target names and instance types from local caches (no API calls)
  and writes an enriched schema to ``.vscode/amlt-config.schema.json``
  so that editors offer autocompletion for known targets and SKUs.

  This runs automatically after ``amlt target list``.  Use this command
  to refresh the schema without re-listing targets.

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt schema uri`

Print a `file://` URI for the schema (for YAML modeline usage).

  Add this as the first line of your config file:

      # yaml-language-server: $schema=<URI from this command>

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt schema validate`

Validate YAML config files against the Amulet JSON Schema.

  Reports all validation errors found in each file.  Also checks for
  near-miss typos in ``submit_args.env`` variable names.  Exits with
  code 1 if any file has errors.

  
  Examples:
    amlt schema validate jobs.yaml
    amlt schema validate a.yaml b.yaml

**Parameters:**

  - `FILES` **(required)** (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
