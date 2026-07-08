# `amlt remove`

Remove experiments from the project or jobs from an experiment.

  Examples:
    * ``amlt remove exp-name0 exp-name1`` removes all jobs in exp-name0 and exp-name1.
    * ``amlt remove exp-name :job-name0 :job-name1`` removes job0 and job1.
    * ``amlt remove exp-name :job*[01]`` removes jobs matching that pattern.
    * ``amlt remove exp-name -s killed`` removes jobs with status "killed".

**Parameters:**

  - `-y`, `--yes`: Answer 'yes' to all interactive questions.
  - `-s`, `--status` `STATUS`: Remove jobs with this status (default: `Sentinel.UNSET`)
  - `--force`: Remove files from storage even if the experiment seems to be invalid.
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `--json-help`: Print command help as structured JSON and exit.
