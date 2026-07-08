# AzureML Metrics Logging

You can log to AzureML metrics from Amulet jobs.
You can do this using “raw”
[azureml run logging in version 1](https://azure.github.io/azureml-cheatsheets/docs/cheatsheets/python/v1/logging/) or
[version 2](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-log-view-metrics?view=azureml-api-2&tabs=interactive)
or (most recommended) using [mlflow](https://learn.microsoft.com/en-us/azure/machine-learning/concept-mlflow?view=azureml-api-2).

To use mlflow, you need to

1. Make sure you `pip install azureml-mlflow`
2. In your code, add
   ```python
   def get_rank():
       if "RANK" in os.environ:
           return int(os.environ["RANK"])
       if "OMPI_COMM_WORLD_RANK" in os.environ:
           return int(os.environ["OMPI_COMM_WORLD_RANK"])
       return None


   import mlflow

   if get_rank() in (0, None):
       # patch some logging functions eg in pytorch lightning or sklearn
       # such that they log without your intervention
       # If you use pytorch lightning, please read below.
       #
       # You can also manually log eg using mlflow.log_metric() and
       # mlflow.log_param().
       # See https://mlflow.org/docs/latest/python_api/mlflow.html
       # for details on both.
       mlflow.autolog()

       # Optionally, intercept plain tensorboard log_scalar calls as well and sends them to AzureML.
       mlflow.pytorch.autolog(log_every_n_step=1)

       # Only start a run if your framework (eg lightning) doesn't already do it for you.
       #
       # You'll notice that calling it removes MLFLOW_RUN_ID from your environment,
       # consecutive calls to mlflow.start_run() will break.
       # This is tracked here: https://github.com/mlflow/mlflow/issues/9499#issuecomment-1701987762
       #
       # Failing to call start_run() will create a new mlflow run every time you log a metric.
       with mlflow.start_run():
           train()  # wrap your training code in here.
   ```

> Mlflow autologging automatically hooks into sklearn, pytorch lightning,
> tensorflow, and more, and logs all parameters and metrics to AzureML.
> If you use lightning, consider using the
> [MlFlowLogger](https://lightning.ai/docs/pytorch/stable/api/lightning.pytorch.loggers.mlflow.html)
> instead.

> There are more things you can do with mlflow and azure, eg. logging artifacts
> – have a look at the
> [documentation](https://learn.microsoft.com/en-us/azure/machine-learning/concept-mlflow?view=azureml-api-2).

# Weights and Biases (wandb)

Amulet has basic support for Weights and Biases. To use wandb,

1. `pip install wandb` locally and run `wandb login`.
2. install wandb library in your job environment (refer to [setup/image_setup](../config_file.md#environment-config))
3. Provide the `WANDB_API_KEY` to your job by adding the following to
   the [submit_args.env](../config_file.md#submit-args-env) section:
   ```yaml
   submit_args:
     env:
       WANDB_BASE_URL: "https://microsoft-research.wandb.io"
       WANDB_API_KEY: "$WANDB_API_KEY"
   ```

   Amulet will populate this environment variable automatically from your
   `~/.netrc` if you ran `wandb login` before.
4. In your code, add
   ```python
   def get_rank():
       if "RANK" in os.environ:
           return int(os.environ["RANK"])
       if "OMPI_COMM_WORLD_RANK" in os.environ:
           return int(os.environ["OMPI_COMM_WORLD_RANK"])
       return None


   import wandb

   if get_rank() in (0, None):
       # You only need to do this if your framework does not already.
       # Eg if you use lightning's
       # WandbLogger (https://lightning.ai/docs/pytorch/stable/api/lightning.pytorch.loggers.wandb.html),
       # then you do not need to call wandb.init() yourself.
       wandb.init()
   ```

#### NOTE
Everyone who has access to your workspace will be able to read your wandb API key.
Get a private workspace if you feel uncomfortable sharing it.

By default, Amulet sets variables so that wandb project, groups and job names
are aligned with Amulet’s project, experiment names, and job names.
In case you want to override these settings, please modify them in your code or in `job.submit_args.env` section.
The variables are
`WANDB_PROJECT`, `WANDB_RUN_GROUP`, `WANDB_NOTES`, `WANDB_NAME`, and `WANDB_RUN_ID`. For map jobs,
Amulet also sets `WANDB_JOB_TYPE` to the name of the map job.

When you `amlt rerun` keeping the results, Amulet will tell wandb to
resume the existing run. To override, set `WANDB_RESUME` in
`job.submit_args.env` or use `--delete-results`.

When using `amlt map`, Amulet sets a variable `WANDB_MAP_RUN_ID`.
To append to an existing wandb run, add the following line to your
command:
`export WANDB_RUN_ID=$$WANDB_MAP_RUN_ID WANDB_RESUME=allow`.

#### NOTE
Amulet only sets the wandb names at submit time. This means, if you rename
a run in wandb or in Amulet later, the changes will not be reflected in the other tool.

## Link to Job in WandB

If you use submit_args.env to configure wandb (or rely on amlt’s default
mechanism), you can use `amlt {status,list} <expname> --wandb` to show deep
links to your wandb instance.
