# `amlt run`

Submits new jobs and experiments.

  Every job from the config file is scheduled unless you name the specific jobs you
  want to run.  The config file is optional: if omitted, amlt looks for a default config
  set via ``amlt project set default-config``, or an ``amulet.yaml`` in the project root directory.

  Examples:

  * Run all jobs in config file:

    ``amlt run config.yaml``

  * Use the default config and run a specific job:

    ``amlt run :job1``

  * Use the default config and pass extra arguments:

    ``amlt run -- --lr 0.5 --epochs 10``

  * Use the default config, append to experiment "foobar", and pass extra arguments:

    ``amlt run foobar -- --lr 0.5``

  * Run a job and stream its output (same as ``amlt log -f <expname>``):

    ``amlt run config.yaml :job1 -f``

  * Run all jobs in config file append to the experiment "foobar". Create "foobar" if it doesn't exist.:

    ``amlt run config.yaml foobar``

  * Run all jobs in config file and replace (or create) experiment "foobar":

    ``amlt run config.yaml -r foobar``

  * Run "job1" from the config file again, but this time name the job "try2" in "foobar":

    ``amlt run config.yaml :job1=try2 foobar``

  * Run the experiment on a different target than what's specified in the config file:

    ``amlt run config.yaml -t mycluster``

  * Run the experiment on a different target and override its sku:

    ``amlt run config.yaml -t mycluster --sku "2x G4 V100"``

  * Run a single job locally (using docker) using all GPUs:

    ``amlt run config.yaml :job1 -t local --devices all``

  * Pass extra arguments to be substituted for ``$EXTRA_ARGS`` in the command string:

    ``amlt run config.yaml -- --lr 0.5 --epochs 10``

  Note that if you do not provide an experiment name, the job will be appended to your default experiment.
  If the default experiment does not exist, a new experiment with a random name will be created.
  To set a default experiment, check the ``amlt project set`` command.

**Parameters:**

  - `{{[CONFIG_YAML] [JOB_REF]...} [EXP]}` (multiple)
  - `-t`, `--target-name` `NAME[:GROUP_POLICY]`: A unique name for a compute target. See "amlt target list SERVICE" for possible values. (default: `Sentinel.UNSET`)
  - `-d`, `--description`: Helps you remember what this experiment is about (default: `Sentinel.UNSET`)
  - `-f`, `--follow`: Stream the stdout of the first submitted job
  - `-r`, `--replace`: Replaces the experiment, if it exists.
  - `--set-default`: Sets the new experiment as default for the project.
  - `--upload-data`: Upload the data specified in the data section of the config file
  - `--no-md5`: Do not compute md5 file checksums. This improves uploading speed, but will always overwrite existing files and disable skipping these files on md5 match in future uploads.
  - `--dump`: Print the (parsed) configuration file and exit. This helpful when you compose configuration files using imports.
  - `-s`, `--search`: Run the search jobs from config.
  - `--code-dir` `DIRECTORY`: Mount this code directory directly into the container (default: `Sentinel.UNSET`)
  - `-x`, `--extra-args`: Will be inserted in place of $EXTRA_ARGS in the command string. Prefer ``-- EXTRA_ARGS...`` syntax instead.
  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `--sku` `SKU_CONSTRAINTS`: Type of SKU to use, eg. 32G2-V100@westus2. See docs for details. (default: `Sentinel.UNSET`)
  - `-y`, `--yes`: Answer 'yes' to all interactive questions.
  - `-c`, `--command`: Custom command to run. If specified, jobs and search section in the yaml file are ignored (default: `Sentinel.UNSET`)
  - `--pre`, `--no-pre`: Indicate that job may be preempted.
  - `-w`, `--ws`, `--workspace` `NAME`: Name of the workspace to use (default: `Sentinel.UNSET`)
  - `--sla` `[Premium|Standard|Basic]`: SLA tier to use (default: `Sentinel.UNSET`)
  - `-a`, `--attach`: Whether to automatically attach to the interactive process as it is launched.
  - `-i`, `--interactive`: Whether to launch the job in interactive mode in a tmux process. Connect to the job with `amlt ssh` or with the "--attach" flag.
  - `--image` `IMAGE_NAME`: To use local image. Overwrites image, sets registry to None (default: `Sentinel.UNSET`)
  - `--az-login`: Mount the Azure login credentials into the container
  - `--docker-opts`: Pass this as options to the docker command (default: `Sentinel.UNSET`)
  - `--devices` `DEVICE_LIST`: Allow accessing this cuda device inside the container. Comma-separated integers or "all". (default: `Sentinel.UNSET`)
  - `--use-sudo`: Use sudo to run docker
  - `-o`, `--output` `DIRECTORY`: Job writes here (needs sudo to change/delete!) (default: `Sentinel.UNSET`)
  - `--json-help`: Print command help as structured JSON and exit.
