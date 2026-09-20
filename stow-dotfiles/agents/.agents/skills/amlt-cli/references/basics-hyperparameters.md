# Grids and Hyperparameter Searches

You can launch a hyperparameter sweep or many similar jobs following a template by defining a `search` field in your config file.

```yaml
search:
  job_template:
    name: "{experiment_name:s}_{auto:3s}"
    sku: G1
    command:
    - python main.py --lr {lr}
  type: hyperdrive
  sampling: random
  max_trials: 4
  parallel_trials: 2
  params:
    - name: lr
      values: log_uniform(0.001, 0.5)
```

The `search` section is completely independent from the jobs section. A `search` requires:

* a `job_template` which contains properties common to all the jobs in the hyperparameter search.
  It takes all the options of a job as specified in the `jobs` section, with some additional features:
  * `name` provides more flexibility by specifying dynamically formatted strings, for example,
    if you want the value of some of your hyperparameter to be reflected in the job name.
  * `command` can use parameters values instantiated by the search mechanism, i.e. `python main.py --lr {lr}`.
    If your commandline becomes too long, have a look at [Long commands](30_jobs.md#long-commands).
* `max_trials` i.e. the maximum number of jobs the search can start.
* a list of `params` on which the search will be performed, you have a [range of options](../config_file.md#search-config) here.

Refer to [config file specification](../config_file.md) for more information, in particular the section about [params](../config_file.md#search-config).

<a id="hyperdrive-vs-amulet"></a>

## HyperDrive vs Amulet Searches

Amulet provides two mechanisms for your hyperparameter searches:

* [HyperDrive](https://docs.microsoft.com/en-us/azure/machine-learning/v1/how-to-tune-hyperparameters-v1)
  - an Azure service that performs hyperparameter search. HyperDrive supports `random`, `grid`, and `bayesian` searches.

  As an azure service, this only works on services `aml` and `manifold`, but not on `volcano`.
* Amulet’s native hyperparameter search that supports `random` and `grid` optimizations.

Although Amulet provides its own hyperparameter search implementation, we recommend using HyperDrive going forward.
It offers three notable improvements over Amulet’s native hyperparameter search:

* The runs are scheduled dynamically. In other words, you can choose to explore 20 hyperparameter configurations
  but have no more than 5 concurrent runs from this search at any time on the cluster.
  Amulet search, on the other hand, queues all trials at once.
* HyperDrive supports Bayesian optimization, offering more sophisticated ways to explore the hyperparameter space.
* HyperDrive supports early termination of runs in grid and random searches, allowing to use compute more efficiently.

#### NOTE
Hyperdrive bayesian optimization is used by default if not specified in your config file.

<a id="hyperdrive-conversion"></a>

### Automatic conversion of Amulet search to HyperDrive

Amulet will attempt to automatically convert `random` and `grid` searches to HyperDrive when all the following conditions are met:

* The search is created within an empty experiment.
* The search is supported by HyperDrive (if `max_trials <= 1000`, it most likely is).
* The automatic conversion is not disabled by setting [`AMLT_TRY_USING_HYPERDRIVE`](../miscellaneous/70_environment_variables.md#envvar-AMLT_TRY_USING_HYPERDRIVE) to “false”.

Only if your search does not meet the above conditions, Amulet will launch it
using its native hyperparameter search implementation (ie, submit all jobs
independently).

In case your search is converted to HyperDrive and you did not set
`parallel_trials` in your config file, Amulet set it the minimum of
`max_trials` and twice your GPU quota on the selected target.

Notice that Amulet will not change your yaml config file. We encourage you to
update your config file to use HyperDrive directly.

You can disable this conversion by setting [`AMLT_TRY_USING_HYPERDRIVE`](../miscellaneous/70_environment_variables.md#envvar-AMLT_TRY_USING_HYPERDRIVE) to `false`.

<a id="hyperdrive-intro"></a>

## HyperDrive

You can submit a HyperDrive experiment using `examples/mnist_pytorch/hyperdrive.yaml`:

```yaml
description: Hyperdrive sweep on AML

target:
  service: aml
  name: canada1GPUcl

environment:
  image: pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
  registry: myregistry.azurecr.io

code:
  local_dir: $CONFIG_DIR/src

search:
  job_template:
    name: "{experiment_name:s}_{auto:3s}"
    sku: G1
    command:
    - python main.py --lr {lr}
  max_trials: 4
  parallel_trials: 2
  metrics:
    - name: loss/train
      goal: minimize
  max_duration_hours: 10
  params:
    - name: lr
      values: uniform(0.001, 0.5)
```

A HyperDrive search allows you to specify:

* A `type` field equals to `hyperdrive`, which is the default in Amulet.
* A `sampling` field, describing the sampling method that HyperDrive should follow (`grid`, `random` or `bayesian`). The default is `bayesian`.
* A `parallel_trials` field. This is the number of concurrent runs that HyperDrive will schedule on the target. It will do so until `max_trials` runs have been submitted.
* A `max_duration_hours` field. This is the maximum number of hours for which the hyperdrive experiment will run (ie will schedule trials and let the trial runs).
  After that duration, the experiment stops and the trials are canceled. The default is 336 hours (14 days) and the maximum allowed 1440 hours (60 days).
* A `metrics` field, containing the name of the metric to optimize, and whether to maximize or minimize it. This is used for two things:
  - Bayesian `sampling`. HyperDrive will explore the hyperparameter space by Bayesian optimization of the metric.
  - Early termination (see below). HyperDrive will early terminate jobs that perform poorly compared to runs with respect to that metric.

  See below on how to log metrics.
* An optional `early_termination` field containing a policy field as described [here](https://docs.microsoft.com/en-us/azure/machine-learning/v1/how-to-tune-hyperparameters-v1#early-termination). Ex: `BanditPolicy(slack_factor=0.15, evaluation_interval=1, delay_evaluation=10)`.
* A `hyperdrive` spec for the `params`, which is the default value, valid for any type of search. When that spec is used, the values allowed are strings of the form:
  - `choice(1, 2, 3)`
  - `uniform(0, 1)`
  - `loguniform(1, 2)`

  Other options are also allowed, check the [full list](https://docs.microsoft.com/en-us/azure/machine-learning/v1/how-to-tune-hyperparameters-v1#define-the-search-space).

#### NOTE
You can also use `params` with the Amulet native specs (e.g. `discrete` or `uniform`) in HyperDrive searches.

### Logging metrics

For Bayesian optimization and early termination, HyperDrive needs to receive metrics from your job. This can be done two different ways:

* For TensorBoardX, PyTorch and TensorFlow < 2 and a few more, you can use [mlflow](../miscellaneous/5_wandb_support.md) to log metrics directly to AzureML and thereby to HyperDrive.
  The name of the metric you specified in your configuration file should correspond to the name of a scalar your code logs. For example, the metric `accuracy/test` in `examples/mnist_pytorch/src/main.py` will be accessible to HyperDrive.

#### NOTE
When running a HyperDrive search for the first time, you will be prompted about sharing your search metadata (hyperparameters and metrics). This is done to improve Microsoft’s products and enable future research. To ensure the privacy and security of your work, source code and personally identifiable information are explicitly excluded from this aggregation. For more information, please reach out to [msr-hpo-data@microsoft.com](mailto:msr-hpo-data@microsoft.com) or our Teams Support channel.

### Running the experiment

Run this config file with:

```bash
$ cd amlt-examples/mnist_pytorch/
$ amlt run hyperdrive.yaml hyperdrive_experiment
```

You will see that 1 job called `hyperdrive_experiment` was submitted (named after the experiment). It is in essence a scheduler, and will in turn submit jobs to the cluster. To make sure things are working properly, run:

```bash
$ amlt status hyperdrive_experiment
```

You should now see a few jobs: the aforementioned scheduler, and various real jobs (at fist `parallel_trial` jobs, and then more as the search unfolds). Details for each job can be obtained by running:

```bash
$ amlt show hyperdrive_experiment
```

As the search progresses, more and more jobs will appear when running `amlt status`.

#### NOTE
HyperDrive is compatible with both cluster groups and regular targets.

<a id="amulet-search-intro"></a>

## Amulet Search

#### WARNING
Amulet Searches are automatically converted to HyperDrive under certain conditions.
Refer to [Automatic conversion of Amulet search to HyperDrive](#hyperdrive-conversion) for more details.

To use Amulet’s search, set the `type` field of your search to `random` or `grid`.
For example in `examples/mnist_pytorch/search.yaml`:

```yaml
description: Hyperparam sweep

environment:
  image: pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
  registry: myregistry.azurecr.io

code:
  local_dir: $CONFIG_DIR/src

search:
  job_template:
    name: "{experiment_name:s}_{auto:3s}"
    sku: G1
    command:
    - python main.py --lr {lr}
  type: random
  max_trials: 2
  params:
    - name: lr
      values: log_uniform(0.001, 0.5)
```

Note that the `sampling` field is not required for an Amulet’s search (it will be ignored if specified).
Also note that it is not possible to set a maximum number of parallel trials.
The `max_trials` limits the total number of trials, but they will all be submitted at once.

#### WARNING
The `max_trials` field of your `search` defines the maximum number of jobs Amulet will submit in parallel.
Use it wisely, especially when running a `grid` search.

Run this config file with:

```bash
$ amlt run search.yaml search_tf_experiment -t <target>


# e.g., to run on the company-wide cluster group, use
$ amlt run search.yaml search_tf_experiment -t ms-shared --pre
```

You will see that 2 jobs (as specified by `max_trials`) were submitted.

To know which values were drawn from the hyperparameters’ distributions, run:

```bash
$ amlt show search_tf_experiment
```

Details for each submitted job include the values of the hyperparameters used.
