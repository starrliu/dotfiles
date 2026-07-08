# `amlt project`

Manage projects (storage account + experiment namespace).
Invoke without command to get the current project status.

**Subcommands:** `checkout`, `create`, `gc`, `list`, `remove`, `set`, `unset`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt project checkout`

Changes active project.

  `<storage-account>` may be omitted only if it is properly set currently.

  If no `<container-name>` or `<registry-name>` is given, default values will be used.

  Optionally, you can provide a `<storage-container-name>`.

**Parameters:**

  - `PROJECT_NAME` **(required)**
  - `STORAGE_ACCOUNT_NAME`
  - `STORAGE_CONTAINER_NAME`
  - `REGISTRY_NAME`
  - `-c`, `--create`
  - `-d`, `--project-dir` `DIRECTORY`: Directory where the project config should be placed. Overrides the AMLT_PROJECT_DIR environment variable.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt project create`

Creates a new project, and checks it out.

  `<storage-account>` may be omitted only if it is properly set currently.
  If no `<container-name>` or `<registry-name>` is given, default values will be used.
  Optionally, you can provide a `<storage-container-name>`.

  The output directory is the directory where logs and results of jobs are downloaded to by default.

**Parameters:**

  - `PROJECT_NAME` **(required)**
  - `STORAGE_ACCOUNT_NAME`
  - `STORAGE_CONTAINER_NAME`
  - `REGISTRY_NAME`
  - `-o`, `--output-dir` `DIRECTORY`: Directory where your logs/results will automatically be downloaded. (default: `Sentinel.UNSET`)
  - `-f`, `--output-storage-path-format`: Format in which results will be organized in the blob storage. By default, it is ``{job_id}``. Another possible value is ``{experiment_name}/{job_name}``. Use with care. (default: `Sentinel.UNSET`)
  - `-b`, `--default-blob-storage`: Storage account where your data/code/logs/results are located. Only specified when creating new projects. While the main storage account argument must by of a Standard V2 account, this storage can be of a Premium or Standard Blob storage account. (default: `Sentinel.UNSET`)
  - `--no-checkout`: Will not checkout the newly created project.
  - `-d`, `--project-dir` `DIRECTORY`: Directory where the project config should be placed. Overrides the AMLT_PROJECT_DIR environment variable.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt project gc`

Trigger garbage-collection of project metadata and blob storage.

  For efficiency reasons, we sometimes do not delete data rightaway and instead regularly garbage-collect it when you run amlt.
  This command triggers garbage collection manually.

**Parameters:**

  - `--override-expiration`: Override expiration date of the artifacts pending to be deleted, therefore forcing the deletion.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt project list`

Lists the projects stored in the storage account provided.

  If no storage account is provided, check for the current storage account if any.
  If no storage container name is provided, use current storage container, if any, or the default.

**Parameters:**

  - `STORAGE_ACCOUNT_NAME`
  - `STORAGE_CONTAINER_NAME`
  - `REGISTRY_NAME`
  - `--legacy`: Lists legacy projects.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt project remove`

Clears specified project.

  Cancel and delete all experiments from the project folder and delete the project from the cloud.
  Also delete the local configuration file.
  If no project is provided, check for the current project name if any.

  If no storage account is provided, check for the current storage account if any.

**Parameters:**

  - `PROJECT_NAME`
  - `STORAGE_ACCOUNT_NAME`
  - `STORAGE_CONTAINER_NAME`
  - `REGISTRY_NAME`
  - `-y`, `--yes`: Assume "yes" as answer to prompts and run non-interactively when possible.
  - `-f`, `--force`: Force removal of project, skipping all errors.
  - `-k`, `--keep`: Keep the empty project directory.
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt project set`

Sets attributes of the current project.

  `default-experiment`:
    When set, ``amlt run`` will append jobs from the yaml to the default experiment when no experiment
    is specified.

  `default-config`:
    Sets a default YAML config file for ``amlt run/debug/map``.  When set, the config file argument
    becomes optional.  The path is relative to the project root.

  `default-output-dir`:
    Modifies the project default output directory.

  `output-storage-path-format`:
    Defines a pattern for the path used when results are written on the output (or default) blob
    storage. By default, it is ``{job_id}``. Another possible value is ``{experiment_name}/{job_name}``. Use with care.

**Parameters:**

  - `VARIABLE` **(required)**
  - `VALUE` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt project unset`

Unsets attributes from the current project.

**Parameters:**

  - `VARIABLE` **(required)**
  - `--json-help`: Print command help as structured JSON and exit.
