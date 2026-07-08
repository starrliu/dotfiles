# `amlt map`

Submit follow-up jobs that consume results of previous jobs.

  The map job is a search or MAP_JOB_NAME specified in MAP_YAML, and is consuming the outputs of jobs in EXP_NAME.

  In the job specification in MAP_YAML, you should reference the results of the preceeding job as
  $$AMLT_MAP_INPUT_DIR which points to the preceeding job's output directory.

  Map jobs can either write to the same directory (modifying the original experiment) or write to $AMLT_OUTPUT_DIR as usual.

  Map jobs will be created in an experiment called "{map-job-name}-{experiment-name}", which you can override with the
  MAP_EXP_NAME argument. Job names in a map experiment are identical to the job names in the (mapped) experiment.

  The MAP_YAML config file argument is optional when a default is configured
  via ``amlt project set default-config <path>`` or an ``amulet.yaml`` exists
  in the project root directory.

  Examples:
  * Run a job "finetune" from map.yaml on all jobs of pretrain-exp-name:

    `amlt map map.yaml :finetune pretrain-exp-name`

  * Run a job "evaluate" from map.yaml on two jobs of pretrain-exp-name:

    `amlt map map.yaml :evaluate pretrain-exp-name :some-job-name :some-other-name`

    `amlt map map.yaml :evaluate pretrain-exp-name :some*`

  * Run the search defined in map.yaml on best-pretrain-job from pretrain-exp-name:

    `amlt map map.yaml --search pretrain-exp-name :best-pretrain-job`

  * If you have a default experiment set up, you can skip the target experiment name:

    `amlt map map.yml :finetune :pretrain-job`

**Parameters:**

  - `-y`, `--yes`: Answer 'yes' to all interactive questions.
  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `--search`: Run the search jobs from map-yaml. Conflicts with MAP_JOB
  - `-s`, `--status` `STATUS`: Only applies mapping to target jobs with specified statuses (default: `Sentinel.UNSET`)
  - `--debug`: Tail log of first job
  - `--debug-interactive`: SSH into the container after launching the job
  - `-t`, `--target-name` `NAME[:GROUP_POLICY]`: A unique name for a compute target. See "amlt target list SERVICE" for possible values. (default: `Sentinel.UNSET`)
  - `-d`, `--description`: Helps you remember what this experiment is about (default: `Sentinel.UNSET`)
  - `-x`, `--extra-args`: Will be inserted in place of $EXTRA_ARGS in the command string. Prefer ``-- EXTRA_ARGS...`` syntax instead.
  - `--sku` `SKU_CONSTRAINTS`: Type of SKU to use, eg. 32G2-V100@westus2. See docs for details. (default: `Sentinel.UNSET`)
  - `-w`, `--ws`, `--workspace` `NAME`: Name of the workspace to use (default: `Sentinel.UNSET`)
  - `--sla` `[Premium|Standard|Basic]`: SLA tier to use (default: `Sentinel.UNSET`)
  - `--pre`, `--no-pre`: Indicate that job may be preempted.
  - `{{[MAP_YAML] [MAP_JOB]} {EXP [JOB_REF]...} [EXP]}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
