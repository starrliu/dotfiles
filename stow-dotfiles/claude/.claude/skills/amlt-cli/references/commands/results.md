# `amlt results`

List, view, download, or share result files from jobs.

  Note that all subcommands can be abbreviated to the shortest unique prefix, e.g.
  ``d`` for ``download``.

**Subcommands:** `download`, `list`, `remove`, `share`, `view`

**Parameters:**

  - `--json-help`: Print command help as structured JSON and exit.

## `amlt results download`

Fetches files written by the model.

  If job names are given, only downloads the given jobs.

  * If `-I`/`--include` is given, only downloads the files that match that pattern.
  * `-I`/`--include` can be specified multiple times to download the files matching any of those glob patterns.
  * If `-s`/`--status` is given, only downloads the files for jobs that have that status. Mostly useful for pass status.

  Examples:

  * Download files with extension ``.tf`` in the output directory for the given two jobs.

    - ``amlt results d exp1 :job1 :job2 --include '*.tf'``
    - ``amlt results d exp1 :job[12] --include '*.tf'``

  * Download all outputs of all successful jobs in the given two experiments.

    - ``amlt results d --status pass exp1 exp2``

  Instead of ``:<job-name>``, you can also use ``@<tag-name>``, ``:<job-id>``, or ``:<index>``
  (for example ``:-1`` for the last job).

**Parameters:**

  - `-s`, `--status` `STATUS`: only jobs with these status values will have the results pulled (default: `Sentinel.UNSET`)
  - `-I`, `--include` `FILENAME/PATTERN`: Only download files with names matching a glob pattern. Ex: ``amlt results d -I "*.txt"`` (default: `Sentinel.UNSET`)
  - `-o`, `--output` `DIRECTORY`: Path to the output directory. The experiment name will be appended. (default: `Sentinel.UNSET`)
  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt results list`

List the results of the first job provided (alias "ls").

  Instead of ``:<job-name>``, you can also use ``@<tag-name>``, ``:<job-id>``, or ``:<index>``
  (for example ``:-1`` for the last job).

**Parameters:**

  - `-u`, `--with-urls`: Create URL with shared access signature for each file
  - `-s`, `--status` `STATUS`: Only consider jobs with these status values (default: `Sentinel.UNSET`)
  - `-I`, `--include` `FILENAME/PATTERN`: Only list files with names matching a glob pattern. (default: `Sentinel.UNSET`)
  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt results remove`

Remove files the job wrote (alias "rm").

  Instead of ``:<job-name>``, you can also use ``@<tag-name>``, ``:<job-id>``, or ``:<index>``
  (for example ``:-1`` for the last job).

**Parameters:**

  - `-s`, `--status` `STATUS`: Only consider jobs with these status values. (default: `Sentinel.UNSET`)
  - `-I`, `--include` `FILENAME/PATTERN`: Only remove files with names matching a glob pattern. (default: `Sentinel.UNSET`)
  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt results share`

Create a zip and a URL that is valid for NUM_DAYS and can be shared with collaborators

  Instead of ``:<job-name>``, you can also use ``@<tag-name>``, ``:<job-id>``, or ``:<index>``
  (for example ``:-1`` for the last job).

**Parameters:**

  - `NUM_DAYS` **(required)**
  - `-I`, `--include` `FILENAME/PATTERN`: Only share files with names matching a glob pattern. (default: `Sentinel.UNSET`)
  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.

## `amlt results view`

Print selected result files to stdout/pager, optionally with syntax highlighting.

**Parameters:**

  - `--filename`, `-f`: Files to fetch from the job(s). (default: `Sentinel.UNSET`)
  - `--line-numbers`, `-n`: Show line numbers.
  - `--pager`, `-p`: Show content in pager.
  - `--color`, `-c`: Force color in pager.
  - `--encoding`, `-e`: Encoding of the text file to view. (default: `ascii`)
  - `--lexer`: Lexer for syntax highlighting, see https://pygments.org/docs/lexers/ for values. Auto-detected by default. (default: `Sentinel.UNSET`)
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
