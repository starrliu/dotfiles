# `amlt ssh`

SSH into a running job.

  Examples:

  * this "reserves" a machine for 7 days and then SSH into it:

    `amlt run examples/mnist_pytorch/simple.yaml my-idle-machine -c "sleep 7d" --sku G8 -t ms-shared`

    `amlt ssh my-idle-machine`

  * This ssh's into your job and allows you to browse the source code in your local browser
    at http://localhost:5554

    `amlt ssh my-experiment -o "-L 5554:localhost:5554" -c "python -m http.server 5554"`

  * For Singularity's managed mode, it is only possible to SSH into jobs that were already launched in interactive mode.

    `amlt run -i ...` followed by ``amlt ssh :myjob``

  * You can also ssh into interactive debugging jobs, eg. if you lost the connection:

    `amlt debug -i my-config.yaml -t my-target`

    `amlt ssh debug-- -c 'printenv' -c 'python resetmodel.py'`

  * To SSH into a specific worker node in a multi-node job, use the --node flag:

    `amlt ssh my-experiment --node 1`  (connects to the first worker node)

  * For ``local`` jobs, this runs ``docker exec`` into the job's running container:

    `amlt run my-config.yaml my-local-job -t local`

    `amlt ssh my-local-job`

  Please be considerate of others and return resources if you do not need them.

**Parameters:**

  - `{EXP [JOB_REF]...}` (multiple)
  - `-o`: Additional options for ssh, eg. port forwarding, space-separated. (default: `Sentinel.UNSET`)
  - `-c`, `--command`: Commands to execute, defaults to 'tmux attach'/'bash' depending on how the job was launched. (default: `Sentinel.UNSET`)
  - `-n`, `--node` `INT [x>=0]`: Node index to connect to. 0 is the master node; 1, 2, ... are worker nodes. (default: `0`)
  - `--json-help`: Print command help as structured JSON and exit.
