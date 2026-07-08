# Distributed training

#### NOTE
If you have a `setup` section in your config, it will be executed only once
on each node in a separate shell. If you define environment variables in
the `setup` section, they will *not* be available in the jobs, you should
define them (again) in the job’s `command`.

## PyTorch

This differs a bit between backends.

\*\*AML:\*\*

By default, jobs are **not** launched in a distributed way, and will **only run once on the first node**.

To launch jobs in a MPI context, set `mpi: True` and `process_count_per_node: 1` or `process_count_per_node: #GPUS_PER_NODE` in your job config.
A value of `-1` will launch one process per GPU on the node.
Note that the `mpirun` command will need to be available in your image.

When setting `process_count_per_node > 0`, jobs with multiple GPUs will be launched in a multi-thread context:

```python
world_size = int(os.environ["WORLD_SIZE"])
local_rank = int(os.environ["LOCAL_RANK"])
world_rank = int(os.environ["RANK"])
node_rank = int(os.environ["NODE_RANK"])
master_ip = os.environ["MASTER_ADDR"]
master_port = os.environ["MASTER_PORT"]
```

These environment variables should be sufficient to initialize via horovod by `horovod.torch.init()`.

To initialize nccl manually,

```python
import torch.distributed as dist

master_uri = "tcp://%s:%s" % (os.environ["MASTER_ADDR"], os.environ["MASTER_PORT"])
dist.init_process_group(
    backend="nccl",
    init_method=master_uri,
    world_size=world_size,
    rank=world_rank,
)
```

By setting `process_count_per_node: 0` (*as is by default*) in the job section of the config file, you will be responsible for spawning processes.

\*\*Manifold:\*\*

If you choose to manually start MPI (by having set `process_count_per_node: 0`), use the following template:

```bash
mpirun $SINGULARITY_MPI_ENV [worker launch command e.g. python path/train.py]
```

For a fully worked example, see the files contained in the `distributed` folder of our
[`examples`](../_static/amlt-examples.zip).

## Some typical examples

The following is an annotated config file illustrating common ways of spawning multiple processes.
Note that you can modify the values in env_defaults by setting them in your environment.
For example, in bash, you can launch with this syntax:
`NODES=4 amlt run some.yml`, which implicitly does an `export` of the
`NODES` variable just for one `amlt run` command.

```yaml
description: Distributed Pytorch examples

env_defaults:
  NODES: 2
  GPUS: 8
  MEM: 32

target:
  service: singularity
  name: amdmi100vc
  workspace_name: amdmi100ws

environment:
  image: amlt-sing/pytorch
  # This uses a curated singularity base image with newest pytorch.
  # Manifold requires a few packages installed in the image. If you set
  # a non-curated image here, Amulet will run the newest installer for you.
  # Note that custom images may not work effectively on all hardware.

  conda_yaml_file: environment.yaml
  # AML/Manifold non-base images: This creates a *new* conda environment.
  # Manifold base images: This modifies the *existing* conda env in the image.

  image_setup:
    # This will build a new docker image starting from the image above.
    # The modified docker image with image_setup will be cached in the AML workspace
    - apt-get install -y libsomedependency-dev
    - pip install azure-storage-blob

  # try to minimize the time spent in setup since the result will not be cached.
  setup: pip install -e .

code:
  local_dir: $CONFIG_DIR/..
  # The location of the directory that contains your code (for uploading).
  # "." is the path where `amlt run` is executed, $CONFIG_DIR is the directory of this config file

storage:
  data:
    storage_account_name: meow
    container_name: data
    mount_dir: /mnt/meow/data
  results:
    storage_account_name: meow
    container_name: results
    mount_dir: /mnt/meow/results

jobs:
  # Best practices for multi-node multi-GPU training
  # Let AML take care of starting processes (recommended)
  - name: process-launched-by-azureml
    sku: ${NODES}x${MEM}G${GPUS}
    command: python main.py -id $$AMLT_EXPERIMENT_NAME-$$AMLT_JOB_NAME
    # Two $ will be replaced with a single $ when loading the yaml.
    # Variables with single $ will be replaced from your local environment before interpreting this yaml file.
    process_count_per_node: ${GPUS}  # default: 0
    # mpi: False
    # Since Amulet v9.4, Amulet no longer tells AML to use mpirun to spawn processes by default
    # Setting "mpi: True" will ask AML to spawn processes with mpirun. Requires openmpi installed in the image.

    # Manifold specific parameters (also apply for examples below)
    # priority: low     # may spend more time in the queue
    # sla_tier: basic   # may be paused any time, but more capacity available

  # Alternatively, launch the processes yourself via torchrun
  - name: process-launch-via-torchrun
    sku: ${NODES}x${MEM}G${GPUS}
    command: torchrun --nnodes=$NODES --nproc_per_node=$GPUS main.py -id $$AMLT_EXPERIMENT_NAME-$$AMLT_JOB_NAME
    process_count_per_node: 1

  # Alternatively, launch the processes yourself via torch.distributed.launch
  - name: process-launch-via-torch-distributed
    sku: ${NODES}x${MEM}G${GPUS}
    command: python -m torch.distributed.launch --nnodes=$NODES --nproc_per_node=$GPUS main.py -id $$AMLT_EXPERIMENT_NAME-$$AMLT_JOB_NAME
    process_count_per_node: 1

  # this works on singularity only, as mpirun parameters in $SINGULARITY_MPI_ENV are set by Manifold.
  - name: manual-mpirun-on-singularity
    sku: ${NODES}x${MEM}G${GPUS}
    command: mpirun $$SINGULARITY_MPI_ENV main.py -id $$AMLT_EXPERIMENT_NAME-$$AMLT_JOB_NAME
    process_count_per_node: 0
```
