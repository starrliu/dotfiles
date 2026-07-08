# `amlt pause`

Pauses experiments or jobs. Use `amlt resume` to resume.

  Examples:

    * ``amlt pause exp-name`` pauses all jobs in exp-name.

    * ``amlt pause exp-name :job-name0 :job-name1`` pauses job0 and job1.

  Instead of ``:<job-name>``, you can also use ``@<tag-name>``, ``:<job-id>``, or ``:<index>``
  (for example ``:-1`` for the last job).

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
