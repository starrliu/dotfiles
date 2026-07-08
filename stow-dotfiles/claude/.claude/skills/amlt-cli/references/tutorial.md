# Submitting a simple job

#### NOTE
For this tutorial, please start by downloading these [`examples`](_static/amlt-examples.zip). They contain our demo experiments with sample code and configuration files.

Now that you have created an Amulet project and found a target where to submit jobs (if not, check [Setting up Amulet](setup.md)), you are ready to submit a simple PyTorch job.

Amulet uses a [YAML](http://yaml.org) config file to specify the information about the jobs you want to run. This includes the docker image to use, the location of the dataset and code, as well as the commands and parameters of your jobs.

The model we are going to train in this tutorial is located in `amlt-examples/mnist_pytorch/src/main.py` in the amlt-examples folder you just downloaded. It is a simple MNIST classifier written in PyTorch.

The basic config file for our model is present in `amlt-examples/mnist_pytorch/manifold_simple.yaml`:

```yaml
description: Simple PyTorch job on Manifold

environment:
  image: amlt-sing/pytorch

code:
  local_dir: $CONFIG_DIR/src

jobs:
- name: high_lr
  sku: G1
  command:
  - python main.py --lr 0.5
- name: low_lr
  sku: G1
  command:
  - python main.py --lr 0.1
```

\*\*Tip:\*\* 

If you name your config file `amulet.yaml` and place it in your project root
(next to `.amltconfig`), you can omit the file path from every `amlt`
command — e.g. `amlt run` instead of `amlt run config.yaml`.

Example config files for other services are available in the same folder. They mostly differ in their target and image specification.
Note that these jobs do not require you to upload any local data. You can check [Description of an Amulet configuration file](config_file.md) for more information on the various fields, and [using data](basics/25_data.md) for data handling instructions.

## Choosing the target

A target section is optional, the target can be also specified in the command line itself.

To find other possible targets, run `amlt target info <service>` where `<service>` is one of `aml|sing` (as also described [here](basics/05_setup_targets.md)) and choose from that list. Let `<target-name>` be the name of the target you picked.

## Submitting the jobs

With that target in hand, either modify the target section of the yaml file (or leave it as is) and run:

```bash
$ cd amlt-examples/mnist_pytorch/
$ amlt run sing_simple.yaml simple_pytorch_experiment
OR
$ amlt run sing_simple.yaml simple_pytorch_experiment -t <target-name>
```

If your config file were named `amulet.yaml`, this would simplify to:

```bash
$ amlt run simple_pytorch_experiment -t <target-name>
```

If everything works, you should see your code being uploaded and 2 jobs scheduled to `<target-name>`.
To list the jobs you just submitted, type:

```bash
$ amlt list [-u] simple_pytorch_experiment
```

The `-u` option, will update their status (we hope they’re already running! :). Specific jobs from a config file can be run and/or launched under different names.

```bash
# Creates an experiment "my_experiment" and run job "low_lr":
$ amlt run sing_simple.yaml :low_lr my_experiment
```

```bash
# Runs the last job from the config file and appends it to "my_experiment":
$ amlt run sing_simple.yaml :-1 my_experiment
```

```bash
# Launches the two jobs as lr01 and lr05 respectively and append them to "my_experiment":
$ amlt run sing_simple.yaml :low_lr=lr01 :high_lr=lr05 my_experiment
```

```bash
# Recreates "my_experiment", submits the jobs in the config:
$ amlt run sing_simple.yaml -r my_experiment
```

On Manifold or AzureML ARC, to submit your jobs as preemptible, simply add `--pre` to the command:

```bash
$ amlt run sing_simple.yaml --pre
```

Alternatively, you can [set jobs as preemptible in the yaml file](config_file.md#job-properties). For Manifold specifically, you can also set the SLA (premium, standard, basic) via `--sla`.

#### NOTE
If your code is under git version control, your current branch, commit, and uncommitted changes are [saved and can be retrieved](advanced/4_repo_snapshot.md).

Once Amulet is done submitting your jobs, it stores information about your job in your project’s Azure storage account’s table storage. This allows you to checkout your project on another client and manage the experiment there as well. It also allows you to share the project with other collaborators.

## Getting the status

To verify the status of your experiment and the jobs it contains, run:

```bash
$ amlt list -u simple_pytorch_experiment
```

or, equivalently, we provide the following alias:

```bash
$ amlt status simple_pytorch_experiment
```

You should then see some information about the experiment.

## Getting the logs

Once your jobs are running, you may want to verify their standard output logs.
Executing:

```bash
$ amlt logs tail -p simple_pytorch_experiment
```

opens the logs of the first job in the experiment in a pager.
Executing:

```bash
$ amlt logs tail -f simple_pytorch_experiment
```

follows the log in real time in the console.
Finally:

```bash
$ amlt logs download simple_pytorch_experiment
```

will download the standard output for each job into a subdirectory of `<project-output-directory>/simple_pytorch_experiment`. To download elsewhere, use `--output <output-path>`.

## Getting the results

Once your jobs are running / finished, you may want to download the data they have written so far. Executing:

```bash
$ amlt results {download|list} [-I <pattern>] simple_pytorch_experiment
```

will download the content of each job’s `os.environ['AMLT_OUTPUT_DIR']` directory into a corresponding subdirectory of `<project-output-directory>/simple_pytorch_experiment`. To download elsewhere, use `--output <output-path>`.
The options control whether to only list files of a job or filter which files to download.

#### NOTE
The folder in which each job writes data is unique. Inside your job’s python code, it can be accessed in the code via `os.environ['AMLT_OUTPUT_DIR']`.
To reference it in the `command` section of your YAML file, use `$$AMLT_OUTPUT_DIR`. (see [Prepare your Code](basics/20_code.md) for more details).
