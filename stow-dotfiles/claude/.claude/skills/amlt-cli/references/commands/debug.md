# `amlt debug`

Run a single job, then either follow logs or ssh to interact. Delete job after.

  The two main modes are as follows:
  * Run a single job, stream the logs, and cancel on ctrl-c.

    ``amlt debug foo.yml [:<job-name>]``

  * Run a single job, ssh into the container, and cancel when connection is closed.

    ``amlt debug -i foo.yml [:<job-name>]``

  The config file argument is optional when a default is configured via
  ``amlt project set default-config <path>`` or an ``amulet.yaml`` exists in
  the project root directory.

  Note: To display AML setup logs in non-interactive mode, set the environment variable AMLT_LOGS_SHOW_AML_SETUP to 'true'.

**Parameters:**

  - `{[CONFIG_YAML] [JOB_REF]}` (multiple)
  - `-e`, `--experiment-name`: set the name of the debug session (default: `debug--`)
  - `-t`, `--target-name` `NAME[:GROUP_POLICY]`: A unique name for a compute target. See "amlt target list SERVICE" for possible values. (default: `Sentinel.UNSET`)
  - `-x`, `--extra-args`: Will be inserted in place of $EXTRA_ARGS in the command string. Prefer ``-- EXTRA_ARGS...`` syntax instead.
  - `--sku` `SKU_CONSTRAINTS`: Type of SKU to use, eg. 32G2-V100@westus2. See docs for details. (default: `Sentinel.UNSET`)
  - `-y`, `--yes`: Answer 'yes' to all interactive questions.
  - `-i`, `--interactive`: Run the debug session using tmux and ssh to the job container once it runs.
  - `-k`, `--keep-results`: Keep debug results under the debug-- job name
  - `--image` `IMAGE_NAME`: Use a local container image (no registry pull). (default: `Sentinel.UNSET`)
  - `-c`, `--command`: Custom command to run. If specified, jobs and search section in the yaml file are ignored (default: `Sentinel.UNSET`)
  - `-w`, `--ws`, `--workspace` `NAME`: Name of the workspace to use (default: `Sentinel.UNSET`)
  - `--sla` `[Premium|Standard|Basic]`: SLA tier to use (default: `Sentinel.UNSET`)
  - `--pre`, `--no-pre`: Indicate that job may be preempted.
  - `--json-help`: Print command help as structured JSON and exit.
