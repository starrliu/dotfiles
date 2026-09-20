# Defining Jobs

Jobs have few mandatory fields, a name, a sku (“stock keeping unit”), and command:

```yaml
jobs:
  - name: simple_job_lr_05
    sku: G1
    command: python main.py --learning_rate 0.5
  - name: simple_job_lr_01
    sku: G1
    command: python main.py --learning_rate 0.1
```

While name and command are largely self explanatory, a quick note on the `sku` field:
In the simplest form, it says how many GPU you need. “G1” is one GPU, “G8” is eight.
You can specify a lot more, for example “[2x32G8-A100-IB@westus2](mailto:2x32G8-A100-IB@westus2)” means that you
want two nodes with 8 A100 GPUs each, connected by infiniband located in the westus2 region.
Specifying this level of detail only makes sense when using Manifold VCs, which offer heterogeneous compute nodes.
In other cases, the hardware properties are determined by the cluster you’re targeting.

You can run a list of jobs simply by defining them in the `jobs` field of your configuration file.
See [Description of an Amulet configuration file](../config_file.md) for advanced options.

The project directory from which your code is executed is the remote equivalent of `code.local_dir`.
You can use a `cd <some-folder>` command in the command list to change the work dir.

A few other pointers for jobs:

* Your jobs can log metrics to AzureML directly or via TensorBoard. Direct
  TensorBoard to write to `$AMLT_OUTPUT_DIR` and use `amlt browse` to view
  logs as they’re written. See [Monitoring](45_monitoring.md) for details.
* There are various ways to run [Distributed jobs](../advanced/51_distributed.md).
* You can run jobs which [build on the output of other jobs](../advanced/1_finetuning.md).

## Environment Variables

When referencing environment variables in your command, note that anything using a *single* dollar sign (`$`) will be read from your *local* environment.
If you want to reference an environment variable in the remote environment, use a double dollar sign escape.

For example, in your command, use `$${AMLT_OUTPUT_DIR}` to reference the output directory in the remote environment.

<a id="long-commands"></a>

## Long commands

To make long command lines readable, you can introduce newlines in the list by indenting the strings as follows:

```yaml
jobs:
  - name: simple_job_lr_05
    command: python main.py --learning_rate 0.5
      --model-type fancy
      --foobar
```

## Handling Signals

In some cases, AzureML can send a signal to your job that it is about to be
terminated. You can handle this signal in your script by writing a checkpoint,
by installing a signal handler for SIGTERM.

## Access Control on AML and Manifold

Your job needs permissions to mount blob storage and to access azure resources.
See [Setup instructions](../setup.md#access-control) to set this up.

## Manifold Concepts

**Manifold Instance Types**: Manifold offers compute nodes from various *series*. Each series may be exposed as different instances (think of these as slices of the node which you can “book”.)
Given your `sku` specification, Amulet has to make some decisions which instance type to target, since AzureML only allows to set up to four instance types.
For this, Amulet considers your quota on the target VC for the chosen SLA as well as job requirements (`sku` field and whether it’s a distributed job).
If Amulet does not do what you want, try prefixing the sku with the series, e.g. `NDv2:32G1-V100`, or set `sku` to the Manifold instance type name directly.

Tools:

* View available instances in your VCs using `amlt target list manifold --verbose`
  (abbr. `amlt tl mani -v`), which also gives you the translation
  between the Amulet sku syntax and Manifold instances.
* View quota for each series using `amlt ti -v sing` (quota is always per series, not per instance type!)
* View instances available for each series using `amlt cache instance-types -s <series>`.
* View instances matching a given pattern using e.g. `amlt cache instance-types -I A100`.
* You can see which instance types a `sku` specification expands to by running `amlt cache resolve-sku [--sla <SLA>] <Manifold VC> <sku>`.
