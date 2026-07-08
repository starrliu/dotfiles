# `amlt resume`

Resumes experiments or jobs that were paused.

  Examples:
    * ``amlt resume exp-name`` resumes all paused jobs in exp-name.
    * ``amlt resume exp-name :job-name0 :job-name1`` resumes job0 and job1.

  Instead of ``:<job-name>``, you can also use ``@<tag-name>``, ``:<job-id>``, or ``:<index>``
  (for example ``:-1`` for the last job).

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
