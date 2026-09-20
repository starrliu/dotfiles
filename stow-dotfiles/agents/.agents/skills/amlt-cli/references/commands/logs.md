# `amlt logs`

View, download, or stream job logs.

  Subcommands can be abbreviated to the shortest unique prefix, e.g.
  ``d`` for ``download``.

**Subcommands:** `download`, `list`, `tail`, `view`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt logs download`

Download log files to disk.

  Examples:

  * Download all logs in experiment "exp1"

    ``amlt logs download exp1``

  * Download logs matching a pattern

    ``amlt logs download exp1 :jobname[123]``

  * Download logs of successful runs

    ``amlt logs download -s pass exp1``

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `-s`, `--status` `STATUS`: Filter jobs to fetch logs for by status. (default: `Sentinel.UNSET`)
  - `--filename`, `-F`: Name of the log file. Supports glob patterns. (default: `['<stdout>']`)
  - `-o`, `--output` `DIRECTORY`: Path to the output directory. The experiment name will be appended. (default: `Sentinel.UNSET`)
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt logs list`

List available log files for a job.

  Example:

    ``amlt logs list exp1 :jobname1``

**Parameters:**

  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt logs tail`

Stream or page through job logs.

  Without ``-f``, prints the last N lines and exits. With ``-f``,
  streams new lines as they are written.

  Examples:

  * Stream logs of a running job

    ``amlt logs tail -f exp1 :jobname1``

  * Open the log in a pager

    ``amlt logs tail -p exp1 :jobname1``

  * Stream logs from a specific node (rank) in a multi-node job

    ``amlt logs tail -f -F blob://rank-1.log exp1 :jobname1``

**Parameters:**

  - `-n`, `--lines` `INTEGER`: Number of log lines to display. (default: `300`)
  - `-f`, `--follow`: Fetch new lines from the log in regular intervals.
  - `-p`, `--pager`: Open (whole) log in a pager.
  - `--filename`, `-F`: Name of the log file. (default: `['<stdout>']`)
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt logs view`

Print log content to the terminal and exit.

  Examples:

  * Print last 100 lines of a job's log

    ``amlt logs view -n 100 exp1 :jobname1``

  * Print a specific log file

    ``amlt logs view -F user_logs/std_log.txt exp1 :jobname1``

  * View logs from a specific node (rank) in a multi-node job

    ``amlt logs view -F blob://rank-1.log exp1 :jobname1``

  * List all available log files (including per-node logs)

    ``amlt logs list exp1 :jobname1``

**Parameters:**

  - `-n`, `--lines` `INTEGER`: Number of log lines to display. (default: `300`)
  - `--filename`, `-F`: Name of the log file. (default: `['<stdout>']`)
  - `-p`, `--pager`, `-P`, `--no-pager`: Display logs in a pager. Default: on when stdout is a TTY.
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
