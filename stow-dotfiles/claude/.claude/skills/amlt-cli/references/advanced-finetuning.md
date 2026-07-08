# Finetuning and evaluation

Often you want to run a second or third job on top of the results of a finished job.
Examples of this are finetuning a pre-trained model or evaluating a learned model on some new data.

This is where `amlt map` comes in. It maps the jobs of a previous experiment to a new experiment.
Each job in the new experiment has access to the results of a job in the
previous experiment via the environment variable `AMLT_MAP_INPUT_DIR`.

Let’s assume that `map.yaml` contains two jobs, “finetune” and “evaluate”.
“finetune” reads the model from `$AMLT_MAP_INPUT_DIR` and writes finetuned models to `$AMLT_OUTPUT_DIR`, whereas
“evaluate” reads the model from `$AMLT_MAP_INPUT_DIR` and writes evaluation results to the same place, `$AMLT_MAP_INPUT_DIR`.
It’s up to you to organize these. For example, “finetune” and “evaluate” could look like this:

```yaml
jobs:
- name: finetune
  command: ./finetune --pretrained-model $$AMLT_MAP_INPUT_DIR/final.model --output $$AMLT_OUTPUT_DIR/finetuned.model
- name: evaluate
  command: ./evaluate --finetuned-model $$AMLT_MAP_INPUT_DIR/finetuned.model --output-dir $$AMLT_MAP_INPUT_DIR --data /mnt/data/foo.zip
```

Let’s run a job from `pretrain.yaml`, then finetune it and evaluate it.
The job name (`finetune` or `evaluate` in this case) is specified using the
[colon syntax](../cli_commands.md#colon-syntax) right after the yaml file:

```bash
# pretrain models
$ amlt run pretrain.yaml pretrain-exp

# finetune *all* models in the experiment ``pretrain-exp``, write results to *new* folder.
# this creates an experiment called "finetune-pretrain-exp"
$ amlt map map.yaml :finetune pretrain-exp

# evaluate the best model, write results to *same* folder.
# this creates an experiment called "evaluate-finetune-pretrain-exp"
$ amlt map map.yaml :evaluate finetune-pretrain-exp :best-model-job-name

# download results (finetuned model and evaluation results)
$ amlt results download finetune-pretrain-exp
```

If your `map.yaml` contains a `search` section, you can also run a finetuning search like this:

```bash
# ...pretrain models, select the best pretrained model...
# ...let's say the best pretrained job was called "best-pretrain-job"

# now run a search based on the selected best model
$ amlt map map.yaml --search pretrain-exp :best-pretrain-job
```

#### NOTE
You can even run a [HyperDrive](../basics/35_hps.md#hyperdrive-intro) search on the selected job.
