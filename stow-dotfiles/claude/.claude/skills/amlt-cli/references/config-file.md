# Description of an Amulet configuration file

Description of the Amulet YAML file section by section:

<a id="target-description"></a>

## Target

(Optional): Defines where your jobs will be submitted. Can be supplied using **amlt run -t <target-name>** instead.

`service`
: The target service platform to interact with (aml, manifold). Job payloads and endpoints will change according to target service.

`cluster`
: Which cluster to use (e.g. [itpeusp100cl](.md#), [canada24](.md#) …).

`vc`
: Your Virtual Cluster (VC) to use (e.g. `msrlabs`, …). There is no `vc` concept on `aml` and `sing`.

`subscription_id`
: Your AML subscription_id to use (e.g. `db9fc1d1-b44e-45a8-902d-8c766c255568`).

`resource_group`
: Your AML resource_group to use (e.g. `canadav100`).

`workspace_name`
: Your AML workspace name to use (e.g. `canadav100ws`).

`group_policy_name`  *(Manifold)*
: Name of the group policy to submit your job under.

`name`  *(opt.)*
: A reference to a cluster and its corresponding fields if available. You can find the list of available target names by running **amlt target list aml/mani**. For example, you may use the `name`: [usscv100cl](.md#) to reference:
  <br/>
  * `service`: `aml`
  * `cluster`: [usscv100cl](.md#)
  * `workspace_name`: `usscv100ws`
  * `resource_group`: `usscv100`
  * `subscription_id`: `d4c59fc3-1b01-4872-8981-3ee8cbd79d68`

Example:

\*\*AML:\*\*

Detailed version:

```yaml
target:
    service: aml
    subscription_id: db9fc1d1-b44e-45a8-902d-8c766c255568
    resource_group: canadav100
    workspace_name: canadav100ws
    cluster: canada1GPUcl
```

Functionally equivalent version:

```yaml
target:
    service: aml
    name: canada1GPUcl
```

\*\*Manifold:\*\*

```yaml
target:
    service: sing
    name: singvcfoobar
    workspace_name: singwsfoobar
```

Alternatively, you can set just a workspace in your config file, and pass the compute target in the command line:

```yaml
target:
  workspace_name: myws
```

Then pass `--target-name` or `-t` when submitting the job: `amlt run config.yaml -t <target>`

<a id="environment-config"></a>

## Environment

Docker configuration to use.

`image`
: Docker image to use for the experiment. The image needs to be of
  the format `repo/image:tag`. For Manifold, custom docker images need to be based on one of the official Manifold images.
  To select a base image, write `amlt-sing` as the `repo` like so:
  `image: amlt-sing/pytorch-1.8.0-cuda11.1-cudnn8-devel`.
  To see the list of available base images, execute `amlt cache base-images`.
  For non-base images, Amulet will run the Manifold installer and validator to adapt them for Manifold.
  If you already did that manually before pushing the image, please set
  [`AMLT_DOCKERFILE_TEMPLATE`](miscellaneous/70_environment_variables.md#envvar-AMLT_DOCKERFILE_TEMPLATE) to “default” or even “none” in your [submit_args.env](#submit-args-env) section.

`setup`  *(opt.)*
: *List* of commands to execute before jobs. These can be any unix-style command, e.g. `- . setup.sh`, or `- python main.py`.
  Note that for compatibility between Manifold and AML compute, use `$$SUDO` instead of `sudo` in your setup commands (see [`SUDO`](miscellaneous/70_environment_variables.md#envvar-SUDO)).

`registry`
: Registry where the image is hosted (defaults to `docker.io` which corresponds to [Docker Hub](https://hub.docker.com/)).
  <br/>
  \*\*Tip:\*\* 
  <br/>
  DockerHub throttles Azure IPs and using external images is discouraged for
  security reasons.  Always push your images to an Azure Container Registry
  (ACR) and set `registry: <your-registry>.azurecr.io`.
  See [Docker Images](basics/15_images.md) for details.

`username`  *(opt.)*
: Registry username, required to use a private image. Amulet will prompt for the corresponding password.

`image_setup`  *(opt.)*
: Can contain commands that modify the docker image. The modified docker image is cached in the AML workspace. **Runs as root.**

`conda_yaml_file`  *(opt.)*
: Specify this field to make Azure ML build the docker image based on a [conda YAML file](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#creating-an-environment-file-manually) and use one of the [Azure ML base images](https://github.com/Azure/AzureML-Containers), e.g., `azureml/openmpi3.1.2-cuda10.2-cudnn7-ubuntu18.04:latest`, as `image`.
  When used with Manifold base images, the conda environment packages will be installed into the base environment instead of creating a new base environment.

`skip_conda_packages_on_sing`  *(opt.)*
: A list of regular expressions. Matching packages in the `conda_yaml_file` will *not* be installed in the Manifold base image.
  Can be used to e.g. exclude python, pytorch or deepspeed already present in the image. The default is to skip `python\b`, `torch`, `tensorflow`, `cudatoolkit`, `deepspeed`, and `pip`.

Example:

\*\*Docker-based environment:\*\*

```yaml
environment:
    image: pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
    registry: myregistry.azurecr.io
```

\*\*Conda-based environment:\*\*

```yaml
environment:
    image: azureml/openmpi3.1.2-cuda10.2-cudnn7-ubuntu18.04:latest
    conda_yaml_file: $CONFIG_DIR/conda-env.yaml
```

<a id="storage-config"></a>

## Storage

(Optional): defines where the experiment files are stored.
By default, everything is uploaded to your project blob storage account.
Each storage defined in this section must have a unique identifier.
To write results to a different location, you must define a storage named `output`.
On Kubernetes targets, PVCs are also supported for `output` (see [PVC Storage (Volcano/K8s)](advanced/62_pvc_storage.md)).
Under each identifier, you must define the following attribute.
See [Storage](basics/25_data.md) for examples and usage guide.

`storage_account_name`
: The name of your Azure Storage account.
  You need to ensure that your job can access this storage account. If you
  can, use the `identity` field of the job to specify how to mount the
  storage. Alternatively, Amulet will try to obtain your storage account’s
  access key and register a datastore using it.

`container_name`
: The name of the container (e.g. subdirectory) in your blob storage.

`file_share_name`
: The name of the [Azure file share](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-introduction) to mount (must exist already).
  Mutually exclusive with `container_name`.

`mount_dir`  *(opt.)*
: If set, storage is mounted to the specified location. By default, it is mounted at “/mnt/<storage_name>”. eg. You can access the data in the default storage from your code using “/mnt/default”. This must be the absolute path.

`local_dir`  *(opt.)*
: If set, will be used to mount local directories in **amlt run -t local**.

`mount_options`  *(AML — partial, Local)*
: A list of blobfuse mount options for the custom storage.  On AML, only
  `--file-cache-timeout-in-seconds=...` is supported; other options are
  ignored.  On the local backend all options are passed through to blobfuse.

`datastore_name`  *(opt.)*
: Use this instead of auto-generating the name.
  If you want to use a Datastore that is already registered
  in your workspace, you can specify the `datastore_name` and none of
  `storage_account_name`, `container_name`, `file_share_name`.

`is_output`
: Optional. If true (default), create a *writable* mount for this storage.

Example:

```yaml
storage:
    output:
        storage_account_name: my_storage_account
        container_name: my_output_container
        mount_dir: /mnt/output
        mount_options: ["-o", "attr_timeout=240"]

    shared_datastore:
        storage_account_name: shared_storage_account
        container_name: shared_container_name
        mount_dir: /mnt/shared_data
```

<a id="code-config"></a>

## Code

Contains information about your model’s code.

`local_dir`
: Location of your code on your machine. A special environment variable `$CONFIG_DIR` can also be used, it points to the directory of the config file. If no `code` section or no `local_dir` is specified, no code will be uploaded.

Example:

```yaml
code:
    local_dir: examples/mnist_tensorflow/src
```

<a id="job-properties"></a>

## Jobs

Defines a list of jobs, where each job in the list can have the following properties.

Fields available on all backends carry no annotation.
Fields limited to specific backends are marked with an italic tag, e.g.  *(Manifold, Volcano)*.

### Basic properties

`name`
: A unique name for each job.

`command`
: List of commands to execute in a job. These commands are executed from the root directory of your code, e.g. the directory specified in `code.remote_dir`.
  This can be any unix-style command, e.g. `. setup.sh`, or `python main.py`.
  If the command line becomes too long to edit comfortably in an editor, read [Long commands](basics/30_jobs.md#long-commands).
  If you need braces (`{`, `}`) in a search command, make sure to escape them using double braces (`{{`, `}}`).

<a id="sku-dsl"></a>

`sku`
: Specifies the number of nodes, number GPUs/CPUs to reserve and GPU/CPU memory.
  <br/>
  For Manifold, this specifies the job’s hardware constraints, so that you
  can control where the job will be executed when you submit your job.
  Job constraints include: GPU type to use, in which region to run the job, and
  whether InfiniBand/NvLink/xGMI is required.
  <br/>
  * GPU nodes: `[#nodes]x [memory-size]G{#gpus} [gpu-types] [IB] [NVLink/xGMI] [CUDA]@[regions]`
  * CPU nodes: `[#nodes]x [memory-size]C{#cpus}@[regions]`
  <br/>
  #### Examples
  <br/>
  | SKU                               | Meaning                                                    |
  |-----------------------------------|------------------------------------------------------------|
  | `G1`                              | One GPU, no matter which one, no matter where              |
  | `G1-NVIDIA`                       | One GPU in the NVIDIA family                               |
  | `G4-AMD`                          | Four GPUs in the AMD family                                |
  | `G4-IB`                           | Four GPUs equipped with InfiniBand                         |
  | `32G2`                            | Two GPUs with 32 GB of memory                              |
  | `G4-V100-P40-K80`                 | Four of either V100s, P40s, or K80s                        |
  | `G4-V100-IB`                      | Four V100s with InfiniBand                                 |
  | `G4-V100@westus2,westus3,eastus2` | Four V100s in any of these regions                         |
  | `G8-NvLink-xGMI`                  | Eight GPUs endowed with either NvLink or xGMI              |
  | `8x G4`                           | Eight homogeneous nodes each with 4 GPUs                   |
  | `8xC1`                            | Eight homogeneous nodes each with one CPU                  |
  | `16C2`                            | Two CPUs with 16 GB of memory                              |
  | `C2@westus2,westus3,eastus2`      | Two CPUs in any of these regions                           |
  | `NDv4:G2`                         | A Manifold instance of the NDv4 series with two GPUs       |
  | `NDv4:2xG8-IB`                    | Two IB-connected nodes of NDv4 series with eight GPUs each |
  <br/>
  The only required fields are the number of GPUs/CPUs and the [G/C] token.

### Distributed & scheduling

`process_count_per_node`
: Default is 0. The number of processes per node; by default only 1 process is started on the head node. A value of -1 means that the process count should equal the number of GPUs.
  For the Volcano and Batch services, a value greater than 1 will require the `torchrun` executable in your image.
  If it’s in some conda environment, be sure to activate it in your `environment.setup` section.

`mpi`
: Enables OpenMPI, default False. If False, the distributed (pytorch) jobs can still use NCCL backend.
  <br/>
  #### NOTE
  MPI is not supported on the Batch service; use PyTorch distributed (torchrun) instead.

`sla_tier`  *(Manifold, ARC, Volcano)*
: Optional. Sets the SLA tier between Premium, Standard and Basic. Visit the relevant docs for [Manifold](https://aml-singularity.azurewebsites.net/concept/sla.html) or [ARC](https://azureml-pipelines-doc-1p.azurewebsites.net/how_tos/1p_migration/azap_migration_best_practices_job_owner.html#job-priority-and-preemption) for more detailed information.
  Note that in ARC clusters, jobs with higher tier will preempt jobs with lower tier.
  <br/>
  On Volcano clusters, the SLA tier determines the scheduling queue:
  Premium → `<namespace>-deserved`, Standard → `<namespace>-opportunistic`, Basic → `opportunistic-cluster`.
  When both `sla_tier` and an explicit `queue` are set, the SLA-derived queue takes priority.
  The explicit queue is kept as a fallback if the SLA-derived queue is rejected by the cluster.

`preemptible`  *(Manifold, ARC)*
: Optional. Determine whether a job can be preempted. If `preemptible: True`, SLA tier is set to “Basic” for Manifold jobs, and “spot” for ARC jobs.
  If `preemptible: False`, jobs run in tier “Premium”.
  <br/>
  #### NOTE
  You can specify either `preemptible` or `sla_tier` (not both) for each job in the yaml file. The command line `--pre/--no-pre` overrides the config of all jobs in the yaml file.

`priority`  *(Manifold, Volcano)*
: Optional (default: Manifold=Medium). Sets the priority for jobs among a certain tier, between High, Medium and Low.

`azml_int`  *(Manifold)*
: Optional. Enables AzureML Interactive mode, such that jobs can be queued up onto themselves (same resource) so that it can recover from preemption/failure.

### Submission arguments

`submit_args`
: Optional. Extra parameters to be sent to the AML API during job submission.
  <br/>
  <a id="submit-args-env"></a>
  <br/>
  `env`
  : Dictionary of environment variables for Bash Jobs. This can be specified as (name, value) pairs, e.g. `DATA_DIR: mnist_data`.
  <br/>
  `max_run_duration_seconds`
  : Cancel the job if it runs longer than this. Also works in combination with HyperDrive hyperparameter searches.
  <br/>
  `container_args`
  : Additional arguments with which the containers should be instantiated.
    <br/>
    `shm_size`
    : Specify size of shm (shared memory) for all GPUs in a container. Similar to shm-size at [https://docs.docker.com/engine/reference/run/#runtime-constraints-on-resources](https://docs.docker.com/engine/reference/run/#runtime-constraints-on-resources).
      <br/>
      #### WARNING
      Container argument `shm_size` currently not supported for Manifold.
      Please specify environment variable `SHARED_MEMORY_PERCENT` in `jobs/submit_args/env` in the config file.
      The variable is expected to be a number between 0 and 1 that represents the fraction of the SKU memory to allocate to shm.
      E.g., `SHARED_MEMORY_PERCENT: 0.5` on a 512Gb SKU, would allocate 50% of the SKU memory (256Gb) for shm.
      <br/>
      #### WARNING
      On `volcano`, the default `shm_size` is 100Gi.
    <br/>
    Extra `docker run` arguments  *(AML, Batch)*
    : Any other keys under `container_args` are passed as `docker run` flags.
      E.g., `cpus: 2` and `memory: 1024` becomes `--cpus=2 --memory=1024`.
    <br/>
    `cpu_limit`, `cpu_request`  *(Volcano)*
    : Supports fractional CPU values, eg 200m.
    <br/>
    `memory_limit`, `memory_request`  *(Volcano)*
    : Supports memory values with units, eg 512Mi, 2Gi.
  <br/>
  `volcano`  *(Volcano)*
  : Volcano/Kubernetes backend-specific options. Currently supports one field:
    <br/>
    `docker_in_docker_mode`
    : Configure Docker-in-Docker support. Accepted values:
      <br/>
      - `none`  *(default)* — no DinD-specific changes to the pod spec.
      - `socket` — mount the host Docker socket at `/var/run/docker.sock`
        (requires cluster policy that allows `hostPath` mounts).
      - `nested` — add an ephemeral `emptyDir` volume at
        `/var/lib/docker` so the job can start its own `dockerd` inside the
        container.
      <br/>
      Non-`none` modes require a whole-node GPU SKU. Amulet grants
      `privileged` mode automatically for whole-node jobs; there is
      intentionally no user-settable `privileged` knob.
      <br/>
      See [Docker-in-Docker on Volcano (docker_in_docker_mode)](advanced/63_volcano_dind.md) for a complete guide and examples.

`tags`
: A list of strings, potentially containing a colon for aml-style key-value tags. Make sure to quote tags containing a colon!

`identity`  *(AML)*
: Can be set to `user`, `managed`, or `none`. If
  `user`, the submitting user’s identity will be used to mount datastores,
  but the job itself still runs without an identity.
  If `managed`, datastores will be mounted using the identity you set up for your cluster,
  and the job itself can identify as this identity using the `ManagedIdentityCredential`.
  The default is to use managed identity on AML Compute if the cluster has identity assigned, and no identity in all other cases.
  Maps to the `identity` field of the [AML job YAML schema](https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-job-command?view=azureml-api-2#yaml-syntax) .

### Examples

Simple:

```yaml
jobs:
- name: high_lr
  command: python main.py --lr 0.5

- name: low_lr
  command: python main.py --lr 0.1
```

Advanced:

```yaml
jobs:
- name: distributed_job
  sku: 2xG2
  command: |
    printenv | grep -i rank
    python main.py
  submit_args:
    env:
      {AMLT_ENV_VAR: env_data}
    container_args:
      shm_size: 32g
```

<a id="search-config"></a>

## Search

Basic hyper-parameter search language.

`max_trials`
: Maximum number of jobs to be scheduled.

`job_template`
: A job template with all the arguments of the `jobs` section above.
  <br/>
  `name`
  : The name argument provides a bit more flexibility here. You can specify dynamic strings behaving similarly to using python formatting, e.g. `{experiment_name:s}_{search_type:s}`, where `experiment_name` will map to the name of your experiment directory and `search_type` to the type of your search (random, grid, etc.). We also provide a special variable `{auto:s}` that reports all the hyperparameters in a ‘_’ separated string. You can specify `{auto:4s}` if you want your hyperparameters names to be abbreviated by their 4-letter prefix for example. Alternatively, all hyper-parameter names (see `params` section below) are also available, so you could also choose something like `{experiment_name:s}_{learning_rate:1.5f}`.
  <br/>
  `command`
  : In search, the command field uses parameters (`params`) instantiated in the search section. I.e. you can specify commands as `python main.py --lr {lr} --dropout {dropout}`. The values of `experiment_name`, `job_name` and `search_type` can also be used, e.g. as `python main.py --run-name {job_name}`.
  <br/>
  `submit_args`
  : Optional section describing more detailed submission arguments for jobs, as described above.

`type`
: Perform a `hyperdrive` search, a `random` search, or a `grid` search (`hyperdrive` is the default, also check [HyperDrive](basics/35_hps.md#hyperdrive-intro) for more details).

`parallel_trials`  *(HyperDrive)*
: Number of concurrent runs that HyperDrive will schedule on the target. It will do so until `max_trials` runs have been submitted. If unspecified, defaults to 1 for `bayesian` sampling, `max_trials` otherwise.

`max_duration_hours`  *(HyperDrive)*
: Maximum duration in hours for the hyperdrive experiment. Will be canceled after that. Defaults to 336 hours (14 days), with a maximum allowed of 1440 hours (60 days).

`sampling`  *(HyperDrive)*
: Sampling method that HyperDrive should follow, one of `grid|random|bayesian`. Default is `bayesian`.

`metrics`  *(HyperDrive)*
: - `name`: name of the metric to optimize. Should be logged by the job, see [HyperDrive](basics/35_hps.md#hyperdrive-intro).
  - `goal`: one of `maximize|minimize`. What to do with the metric.

`early_termination`  *(HyperDrive)*
: Optional. Early termination policy, see [here](https://docs.microsoft.com/en-us/azure/machine-learning/v1/how-to-tune-hyperparameters-v1#early-termination) for more details.

`optimizer_url`  *(HyperDrive)*
: Optional. URL to a custom optimizer, see [this page](https://dev.azure.com/hdext/_git/hdext) for more details. If specified, the `sampling` field will be ignored.

`optimizer_settings`  *(HyperDrive)*
: Optional. A dict containing settings for the custom optimizer.

`params`
: Describes the distributions of each hyperparameter. The value is a list, and each item in the list has the following properties:
  <br/>
  `name`
  : Name of the hyperparameter.
  <br/>
  Defining the values of your parameter can be done via `spec` and the corresponding fields:
  <br/>
  `spec`: `hyperdrive` (default)
  : Valid for any type of search. Pair with `values`: a hyperdrive parameter specification, e.g. `choice(1, 2, 3)`, `uniform(0, 1)`, `loguniform(1, 2)` — [full list here](https://docs.microsoft.com/en-us/azure/machine-learning/v1/how-to-tune-hyperparameters-v1#define-the-search-space).
  <br/>
  `spec`: `discrete`
  : Pair with `values`: the list of possible values the hyperparameter can take, e.g. `values: [0.5, 0.9, 0.99]`.
    Or a string that we assume is a python expression that evaluates to a list.
    It can be based on numpy (imported as np, needs to be installed separately on your system), e.g. `values: "[1/10**i for i in range(5)]"` or `values: "np.arange(1,12,0.5)"`.
    You can also call a function that returns a list, like so:
    `values: "importlib.import_module('my.module').param_generator()"`
  <br/>
  `spec`: `log_uniform` or `uniform`
  : Can only be used when `type` is `random`. Pair with:
    <br/>
    - `low`: low end of the distribution (needs to be positive if using `log_uniform`).
    - `high`: high end of the distribution (needs to be positive if using `log_uniform`).

`seed`  *(opt.)*
: If given, use this to initialize random number generator used to select which jobs to run.

Example:

```yaml
search:
    job_template:
        name: "{experiment_name:s}_{lr:.5f}_{random_string:s}"
        sku: G1
        command: python main.py --momentum {momentum} --lr {lr} --dropout {dropout}
    type: random
    max_trials: 2
    params:
        - name: momentum
          spec: discrete
          values: [0.5, 0.9, 0.99]
        - name: lr
          spec: log_uniform
          low: 0.001
          high: 0.5
        - name: dropout
          values: choice(0.5, 0.9)
```

<a id="env-var-interpolation"></a>

## Using environment variables

Local environment variables can be referenced directly in your configuration files. This is valid in all sections,
which can be useful for passing variables to the `command` or `environment.setup` sections.

Example:

```yaml
jobs:
    - name: $USER-simple-job
      sku: 2xG2
      command: python main.py
```

If the environment variable is not defined when loading the config file, Amulet will error out.
To avoid the error, you can be provide a default value in a special `env_defaults` section:

```yaml
env_defaults:
  USER: root

jobs:
    - name: $USER-simple-job
      sku: 2xG2
      command: python main.py
```

In order to prevent local environment variable substitution, prefix `$$` to your  environment variable names.
This is useful when referencing remote environment variables.

Example:

```yaml
jobs:
    - name: low-lr
      sku: 2xG2
      command: python main.py --model_checkpoint $$MODEL_PATH
```

<a id="composing-configs"></a>

## Composing configuration files

You may want to compose config files. In this case, you can use the `!include` directive to include another file.
If this file contains anchors, you can reference them in the remaining file.

#### NOTE
Anchors (starting with `&`) and aliases (starting with `*`) are a standard YAML mechanism that can be used to reference the same value in multiple places.
An anchor marks a place in the YAML file, and an alias refers to that place. Additionally, you can use the special `<<` key to merge dictionaries.

These mechanisms normally only works within the same file, but Amulet allows you to include a file and then reference its anchors in the remaining file.

Since substitutions may become somewhat complex, you can use `amlt run --dump config.yaml` to see the final configuration without submitting any jobs.

Example: `common.yaml`

```yaml
.submit_env: &submit_env
  _AZUREML_SINGULARITY_JOB_UAI: my-job-identity  # short name or full resource ID; omit if workspace has only one UAI

.setup: &setup
  conda activate foo

.targets:
 - target: &sing
     service: sing
     name: msrresrchvc
     workspace_name: testws

 - target: &aml
     service: aml
     name: ci-cluster
```

Note that this `common.yaml` does not have a schema, e.g., all the names
starting with periods as well as the anchor names are completely up to you.

What follows is an amlt config file, which references some of the anchors in `common.yaml`.
After substitution, the final configuration file should be valid according to the schema.

Example: `job.yaml`

```yaml
requires:
  - !include common.yaml

environment:
  image: amlt-sing/pytorch

target: *sing

jobs:
- name: sleepy
  sku: C1
  submit_args:
    env:
      <<: *submit_env
      FOO: bar
  command:
  - *setup
  - sleep 1
```

The `requires` section here is just a scratch space that is expanded during YAML parsing but removed before schema validation. Everything you don’t reference using anchors is silently ignored.

You can also include a file in a different position if you want to use all its contents – not just the anchors – as in the following example:

`my_target.yaml`:

```yaml
name: my_target_name
service: aml
```

`config.yaml`:

```yaml
target:
  !include my_target.yaml

...
```

<a id="schema-editor-support"></a>

## Schema / Editor Support

Amulet ships a [JSON Schema](https://json-schema.org/) for its YAML config files,
enabling autocompletion, inline validation, and hover documentation in editors.

**Browsing the schema**

`amlt schema show config` prints the full JSON Schema.  More usefully, you can pass a
dot-separated field path to drill into a specific section — handy when you want
to check which keys are available, what values are allowed, or what a field does:

```bash
amlt schema show config                        # full schema
amlt schema show config jobs                    # everything under 'jobs'
amlt schema show config jobs.sku                # allowed SKU values
amlt schema show config jobs.submit_args.env    # env-var forwarding hints
amlt schema show config target.service          # target → service (with enum)
```

Other subcommands:

```bash
# Print the installed file path
amlt schema path

# Print a file:// URI (for YAML modeline)
amlt schema uri
```

**VS Code (Red Hat YAML extension)**

The schema is automatically installed to `.vscode/amlt-config.schema.json`
on every `amlt` invocation (once per amlt version).  To enable autocompletion
and validation, install the [Red Hat YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)
extension, then add a modeline to your config files:

```bash
# In your project directory:
amlt schema add *.yaml            # inject modeline into all YAML files
amlt schema add jobs.yaml         # or specific files
```

This inserts a `yaml-language-server` modeline as the first line of each file,
pointing at the schema via a relative path.  The modeline and the
`.vscode/amlt-config.schema.json` file are safe to commit — they use relative
paths that work on any machine.

Running `amlt schema add` without arguments prints the modeline for manual use:

```yaml
# yaml-language-server: $schema=.vscode/amlt-config.schema.json
description: My experiment
environment:
  image: pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
  registry: myregistry.azurecr.io
...
```

#### NOTE
To disable the automatic copy to `.vscode/`, set the environment variable
`AMLT_VSCODE_SCHEMA=0`.

**Neovim / other LSP-aware editors**

Any editor that speaks the
[yaml-language-server](https://github.com/redhat-developer/yaml-language-server)
protocol will pick up the modeline described above.  For Neovim, make sure you
have `yaml-language-server` installed (`npm i -g yaml-language-server`) and
configured in your LSP client (e.g. `nvim-lspconfig`).

Alternatively, you can point your editor at the global schema path printed by
`amlt schema uri` instead of the `.vscode/` copy.
