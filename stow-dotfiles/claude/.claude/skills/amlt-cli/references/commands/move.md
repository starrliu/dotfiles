# `amlt move`

Rename jobs or experiments.

  * rename experiment 'foo' to 'bar'

    * ``amlt mv foo=bar``

  * move given jobs in experiment 'foo' to experiment 'bar'

    * ``amlt mv foo :job1 :job2 bar``
    * ``amlt mv foo :job[12] bar``

  * rename a job

    * ``amlt mv foo :job1=job2``

  Use ``amlt create`` to create new (empty) destination experiments.

**Parameters:**

  - `{{EXP [JOB_REF]...} [EXP]}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
