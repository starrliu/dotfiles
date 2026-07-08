# Service selection

## Command line argument

You may pass the name of the service as an argument to the `target` command to switch services. For example, to view the current resources for a service:

```shell-session
$ amlt target info manifold
```

This will also display the predicted co2 intensity (in pounds per kWH) of the energy consumed by the cluster over the next hour. That duration can be customized with the `-l/--length` option. To view the list of clusters and their metadata, run:

```shell-session
$ amlt target list sing
```

#### NOTE
You can define a default service by setting your local [`AMLT_DEFAULT_SERVICE`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DEFAULT_SERVICE) environment variable to one of `aml|singularity|batch`.

Furthermore, the `run` command also accepts the name of the cluster if you already know which service you’d like to use.

The following command will submit to the specified target in the command-line without modifying the configuration file.

```shell-session
$ amlt run simple.yaml -t itplabrr1cl1
```

## Targets

To display the list of resources per target, use the **amlt target list** command:

```shell-session
$ amlt target list

TARGET_NAME      SERVICE  CLUSTER          VC        SUBSCRIPTION_ID                       RESOURCE_GROUP    WORKSPACE_NAME    METADATA
itplabrr1cl1     amlk8s     itplabrr1cl1     resrchvc  46da6261-2167-4e71-8b0d-f4a45215ce61  researchvc        resrchvc          card: V100, gpus: 8
itpscusv100cl    amlk8s     itpscusv100cl    resrchvc  46da6261-2167-4e71-8b0d-f4a45215ce61  researchvc-sc     resrchvc-sc       card: V100, gpus: 8
itpseasiav100cl  amlk8s     itpseasiav100cl  resrchvc  46da6261-2167-4e71-8b0d-f4a45215ce61  researchvc-sea    resrchvc-sea      card: V100, gpus: 8
itpeastusv100cl  amlk8s     itpeastusv100cl  resrchvc  46da6261-2167-4e71-8b0d-f4a45215ce61  researchvc-eus    resrchvc-eus      card: V100, gpus: 8
```

## Adding targets

When adding a workspace (see below), Amulet asks you whether you want to add all targets it has attached.
You can later update the targets using **amlt workspace sync**.

To add individual targets to Amulet, check **amlt target add -h**. For instance,

```shell-session
$ amlt target add --service aml --subscription  <foo> --resource-group <bar> --workspace-name <barfoo>
```

will add to Amulet all the clusters from the workspace `<barfoo>` of that subscription. You will then see them when running **amlt ti aml**.

## Adding workspaces

To add new workspaces to Amulet, check **amlt workspace add -h**. For instance,

```shell-session
$ amlt workspace add <wsname>
```

will add the workspace `<wsname>` to Amulet, auto-discovering its resource
group and subscription from the name via Azure Resource Graph (only `Reader`
is required). Pass `--subscription <foo> --resource-group <bar>` to
disambiguate when several workspaces share the name. You will then see them when
running **amlt wl**.
