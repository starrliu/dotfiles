# `amlt list`

List all experiments in the current project or jobs in the given experiments.

  Examples:
    * ``amlt list expname`` list all jobs in experiment "expname".
    * ``amlt list expname :low_lr :high_lr`` list the given jobs.
    * ``amlt list expname :*lr`` list jobs matching the pattern.
    * ``amlt list -n 5`` show only the 5 most recent experiments.
    * ``amlt -P demo list`` list experiments in project ``demo`` without switching.

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `-t`, `--terse`: Show only experiment names (fast).
  - `-u`, `--update-status`: Update the status of all experiments.
  - `-r`, `--calculate-result-size`, `--no-calculate-result-size`: (Re-)calculate space used by results of all experiments. Use --no-calculate-result-size to skip calculation.
  - `-s`, `--filter-status` `STATUS`: Only jobs with that status, or experiments containing jobs with that status are displayed (default: `Sentinel.UNSET`)
  - `--filter-cluster`: Only show experiments targeting this cluster (case-insensitive regex). Only applies when listing experiments. (default: `Sentinel.UNSET`)
  - `--filter-vc`: Only show experiments targeting this virtual cluster (case-insensitive regex). Only applies when listing experiments. (default: `Sentinel.UNSET`)
  - `-l`, `--loop-interval` `INTEGER`: If non-zero, update status in this interval (default: `0`)
  - `-n`, `--most-recent` `INTEGER`: Show only most recent experiments/jobs. (default: `Sentinel.UNSET`)
  - `-N`, `--most-recent-jobs` `INTEGER`: Per experiment, only summarize the N most recent jobs. (default: `Sentinel.UNSET`)
  - `-e`, `--list-experiments`: Force listing experiments.
  - `-c`, `--columns` `COLUMNS`: only show columns with these names (comma-separated list). Overrides AMLT_LIST_COLUMNS. (default: `all`)
  - `--hide-urls`: Do not show links pointing to backend portal.
  - `-v`, `--verbose`: Increase the information shown.
  - `-f`, `--force-hd-refresh`: Force the fetching of all jobs created by HD experiments.
  - `--force-status-update`: For the status to be refreshed for selected jobs, even from terminal states.
  - `--wandb`: Show wandb URLs when applicable
  - `[EXP [JOB_REF]...]` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
