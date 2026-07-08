# `amlt cancel`

Cancels experiments or jobs by sending a kill signal to the remote service.

  Example:

    * ``amlt cancel exp-name0 exp-name1`` cancels all jobs in exp-name0 and exp-name1.
    * ``amlt cancel exp-name :job-name0 :job-name1`` cancels job0 and job1.
    * ``amlt cancel exp-name :job*[01]`` cancels jobs matching that pattern.

  Specific job canceling can only be performed on 1 experiment at a time.

  Instead of ``:<job-name>``, you can also use ``@<tag-name>``, ``:<job-id>``, or ``:<index>``
  (for example ``:-1`` for the last job).

**Parameters:**

  - `-s`, `--status` `STATUS`: Only jobs with that status are selected (default: `Sentinel.UNSET`)
  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `-y`, `--yes`: Answer 'yes' to all interactive questions.
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
