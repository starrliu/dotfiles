# `amlt rerun`

Run selected jobs again with possibly updated code.

  By default, reruns all failed jobs without reuploading anything, replacing the
  existing job in the experiment. The new job's output directory will contain the
  files written by the old job it replaces.

  Depending on the options you choose, you can run in a new experiment instead
  of replacing the existing job, or discard previous results.

**Parameters:**

  - `--copy-to`: Copy to a new experiment instead of rerunning in the old one. (default: `Sentinel.UNSET`)
  - `--upload-code`: Upload the code specified in the code section of the config file
  - `--code-dir` `DIRECTORY`: Location of code if it cannot be inferred (default: `Sentinel.UNSET`)
  - `-s`, `--status` `STATUS`: Only jobs with these status values are rerun (default: `Sentinel.UNSET`)
  - `--force`: Rerun jobs with status "unknown".
  - `-y`, `--yes`: Answer 'yes' to all interactive questions.
  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `--delete-results`: Delete the old results before rerunning.
  - `--sku` `SKU_CONSTRAINTS`: Type of SKU to use, eg. 32G2-V100@westus2. See docs for details. (default: `Sentinel.UNSET`)
  - `--image` `IMAGE`: Overwrites the docker image of each job in the experiment (default: `Sentinel.UNSET`)
  - `--process-count-per-node` `PROCESS_COUNT_PER_NODE`: Overwrites the number of processes in each node (default: `Sentinel.UNSET`)
  - `-d`, `--description` `DESCRIPTION`: Overwrites the description of the experiment (default: `Sentinel.UNSET`)
  - `-t`, `--target-name` `NAME[:GROUP_POLICY]`: A unique name for a compute target. See "amlt target list SERVICE" for possible values. (default: `Sentinel.UNSET`)
  - `-w`, `--ws`, `--workspace` `NAME`: Name of the workspace to use (default: `Sentinel.UNSET`)
  - `--sla` `[Premium|Standard|Basic]`: SLA tier to use (default: `Sentinel.UNSET`)
  - `--pre`, `--no-pre`: Indicate that job may be preempted.
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
