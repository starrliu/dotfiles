# Working with default experiments

If your workflow tends to involve appending to a single experiment over and over,
default experiments can make your life easier.

Let’s say you have the following config file:

```yaml
environment:
  image: pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
  registry: myregistry.azurecr.io

code:
  local_dir: $CONFIG_DIR/src

jobs:
  - name: train
    command: python main.py
```

Without a default experiment, this command:

```shell
$ amlt run amulet.yaml :train
```

will create a new experiment with a random, unique name, and the lonely “train” job in it.

\*\*Tip:\*\* 

If your config file is named `amulet.yaml`, you can omit it entirely:
`amlt run :train`.

In Amulet, you can set a default experiment as follows:

```shell
$ amlt create main --description 'default experiment'
$ amlt project set default-experiment main
```

You can also set the default experiment by the shortcut:

```shell
$ amlt cde main
```

Now, all commands will apply to the experiment `main` if not specified otherwise.

```shell
$ amlt run config.yaml :train               # appends job "train" to experiment "main"
$ amlt run config.yaml :train=train-try-2   # appends job "train" as "train-try-2" to experiment "main"
$ amlt status         # shows status for jobs in experiment main
$ amlt log -p :-1     # shows log for last job submitted in main
$ amlt cancel :train  # cancels the job "train" in experiment "main"
$ amlt list           # shows only jobs in default experiment without updating the status
$ amlt list -e        # shows all experiments
```

To make sure that hyper parameter searches do not clutter your default experiment,
you should provide a name, e.g.:

```shell
$ amlt run search.yaml -t <target> learnrate-sweep
$ amlt status learnrate-sweep
... etc.
```
