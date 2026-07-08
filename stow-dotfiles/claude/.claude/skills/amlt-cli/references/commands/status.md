# `amlt status`

Show the status of jobs and experiments.

  Example:

  * Prints the status of exp1 and exp2

    * ``amlt status exp1 exp2``

  * Prints the status of jobs 1 and 2 in experiment exp1 only.

    * ``amlt status exp1 :job1 :job2``
    * ``amlt status exp1 :job[12]``

  * Show only the 3 most recent jobs.

    * ``amlt status -n 3 my_experiment``

  * Monitor the status of the experiment exp1 until all jobs terminated.

    * ``amlt status --loop-interval 5 --hide-urls exp1``

  Instead of ``:<job-name>``, you can also use ``@<tag-name>``, ``:<job-id>``, or ``:<index>``
  (for example ``:-1`` for the last job).

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `--calculate-result-size`, `--no-calculate-result-size`: Calculate space taken up by results. Use --no-calculate-result-size to skip calculation.
  - `-s`, `--filter-status` `STATUS`: Only jobs with these status values are displayed (default: `Sentinel.UNSET`)
  - `-n`, `--most-recent` `INTEGER`: Show only most recent experiments/jobs. (default: `Sentinel.UNSET`)
  - `-l`, `--loop-interval` `INTEGER`: If non-zero, update status in this interval (default: `0`)
  - `--hide-urls`: Do not show portal URLs in output.
  - `-v`, `--verbose`: Increase the information shown.
  - `-f`, `--force-hd-refresh`: Force the fetching of all jobs. Only applies to an HD experiment.
  - `--force-status-update`: For the status to be refreshed for selected jobs, even from terminal states.
  - `--wandb`: Show wandb URLs when applicable
  - `--no-update-db`: Do not write status updates back to storage. Useful with read-only storage access.
  - `{EXP [JOB_REF]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
