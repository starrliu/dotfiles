# Setting up Amulet

## Installation

### Prerequisites

You should be using python version >=3.10, and <=3.13. Your jobs can run any python version.

### Isolated Environment Setup (Recommended)

To isolate your projects from your operating system and its python packages, we
recommend you use either a virtualenv or install a separate python distribution through [miniconda](https://docs.conda.io/en/latest/miniconda.html).

\*\*Linux/WSL
.. tabs::
     .. group-tab:: venv:\*\*

> > Make sure your linux has one of the recommended python versions
> > installed. Then, in your project folder, do (substituting the desired python version):

> > ```bash
> > $ python3.8 -m venv venv
> > $ source venv/bin/activate
> > ```

> > Note that the selected python version will be available as `python` in the active virtualenv.
> > To exit the environment, run `deactivate`.

> \*\*conda:\*\*

> If you’re unfamiliar with Miniconda, here are a few steps to get started. This will create an isolated conda environment named `amlt`.

> ```bash
> $ wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
> $ sh Miniconda3-latest-Linux-x86_64.sh
> ```

> From here, reinitialize your shell (with `source ~/.bashrc` or `bash --login` etc…) or open a new terminal and run:

> ```bash
> $ conda create -n amlt10 python=3.8
> $ conda activate amlt10
> ```

> To exit the environment, run `conda deactivate`.

> \*\*pipx:\*\*

> [pipx](https://github.com/pypa/pipx) allows one to run python programs in isolated environments.
> In our context, it gets rid of the need to dedicate a custom conda or virtualenv environment to amulet.
> The following commands install `pipx` for you.

> ```bash
> $ python3 -m pip install --user pipx
> $ python3 -m pipx ensurepath
> ```

\*\*Windows
.. tabs::
     .. group-tab:: venv:\*\*

> > From the app store, install one of the supported python versions. Then, in
> > your project root, do (substitute the desired python version):

> > ```bash
> > $ python3.8 -m venv venv
> > $ .\venv\Scripts\activate
> > ```

> > Note that the selected python version will be available as `python` in the active virtualenv.
> > To exit the environment, run `deactivate`.
> > Also note that there may be issues with windows defender that result in an inexplicable `OSError`.
> > In this casee, please switch to the conda installation method.

> \*\*conda:\*\*

> After running the Miniconda installer, open up the anaconda prompt and run:

> ```bash
> $ conda create -n amlt10 python=3.8
> $ conda activate amlt10
> ```

> To exit the environment, run `conda deactivate`.

\*\*MacOS
If you are using a Mac with an Intel processor, you can use a virtualenv or conda
and install Amulet as you would on Linux/WSL.:\*\*

If you are using a Mac powered by an M-series processor, you will need to install Amulet in
an x-64 compatible conda environment. Note that this is a limitation of AML, not of Amulet.

\*\*conda osx-64:\*\*

From a Apple M1 conda installation, create an environment with osx-64 subdir.

```bash
$ CONDA_SUBDIR=osx-64 conda create -n amlt10 python=3.10
$ conda activate amlt10
$ conda config --env --set subdir osx-64
```

\*\*conda x86_64:\*\*

Please download and install the `Intel x86_64` conda installation, not the `Apple M1` one.
This version of conda will run on your M1 processor, but will install packages for the x86_64 architecture (running on Rosetta 2).
Please refer to the following [user guide](https://docs.conda.io/projects/conda/en/latest/user-guide/install/macos.html).

```bash
$ conda create -n amlt10 python=3.8
$ conda activate amlt10
```

<a id="install-commands"></a>

### Installing Amulet

#### NOTE
If you plan on contributing, please follow these [instructions](contributing/91_contributing.md) instead.

First, make sure that you have an up-to-date pip by running:

```bash
$ python -mpip install -U pip
```

In your conda/virtual  environment, run *one of these commands*:

```bash
# Option 1: stable releases
$ pip install -U amlt --index-url https://msrpypi.azurewebsites.net/stable/leloojoo

# Option 2: nightly releases (replace VERSION with the latest version number)
$ pip install -U "amlt>=VERSION.dev0" --index-url https://msrpypi.azurewebsites.net/nightly/leloojoo

# Option 3: stable/nightly via pipx (obviates the need to create custom conda or amulet environment)
$ pipx install amlt --pip-args=' --index-url https://msrpypi.azurewebsites.net/stable/leloojoo'

# Option 4: stable/nightly via uv (fast alternative to pip/pipx)
$ uv tool install amlt --index-url https://msrpypi.azurewebsites.net/stable/leloojoo
```

*Optionally*, to enable **command line tab-completion**, please visit the [following section](miscellaneous/61_cli_completion.md).

#### NOTE
Note that our package name is `amlt` and is not related to another python package `amulet`. If you installed `amulet` by accident, please uninstall it before installing `amlt`.

You should now be able to use the tool, try it by running `amlt --help`. If this did not work, see troubleshooting at the bottom of this page, follow the [instructions for contributors](contributing/91_contributing.md) instead, or reach out on the Amulet Teams channel ([https://aka.ms/amulet-on-teams](https://aka.ms/amulet-on-teams)).

#### NOTE
Note that if you plan to use `amlt metrics` a lot, you may want to directly
`pip install -U amlt[metrics]...`, which adds a few additional dependencies
that allow you to eg parse tensorboard files, fetch AzureML metrics, or
flatten yaml files.

<a id="storage"></a>

## Azure Storage Account

### Creation

Your data, your code, the information about your experiments, the output of your jobs, etc, are stored by Amulet on an Azure storage account you own.
If you already have one, all you need are its name and access key.
If you’re an intern, please ask your mentor to create a storage account for you.

\*\*Click to see instructions for creating a storage account (if you don’t have one)\*\*

Visit the [Azure portal](https://ms.portal.azure.com) and follow these steps:

> + Click on  *+ Create a resource*
> + Look for and click on *Storage Account*
> + Select a subscription
> + Create (or select) a resource group
> + Provide a name for your Azure Storage Account, e.g. your_username
> + Select a region. Amulet meta-data is small, so this is not that critical.
>   If your jobs happen to run on compute in another region, you may want to
>   consider setting up additional storage accounts later solely for
>   input/output.
> + Under “Performance”, make sure to choose “Standard”. You can also use an *additional* “premium”
>   storage account for your files (i.e. blob storage), but you will need one
>   “Standard” account with Azure Tables support for your metadata.
> + In Redundancy, select Locally-redundant storage
> + Click *Review + Create*.

<a id="access-control"></a>

## Access Control for Storage Accounts and Azure Container Registries (ACR)

### Using Identity-based Access (recommended)

Amulet users should have the [Storage Blob Data Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor) and [Storage Table Data Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-table-data-contributor) roles.
This way, Amulet is able to access the storage account without first obtaining an access key.

Jobs also need to use some form of identity to access your storage and your image. The way this is done differs between services (AML/Manifold).

On **AML Compute**, create a managed (“user-assigned”) identity and assign it to your cluster.
This can be done directly in the AzureML Portal.
You can reuse the same identity for multiple clusters.
Ensure that this identity has the [Storage Blob Data Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor)
role on all storage accounts you need to access.
Also, make sure this identity has the AcrPull role for all azure container registries you intend to use.

Your workspace itself also has a managed identity, which may need the AcrPull
role on all azure container registries (ACR) you will access.
When you add a role in azure portal, click managed identity (not users), select the
subscription your workspace is in, select Azure Machine Learning Workspaces,
and then your workspace.

On **Manifold**, follow these steps:

1. Follow [this guide from singularity](https://aml-singularity.azurewebsites.net/guide-for-admin/use-managed-identity.html)
   or [this guide from GCR](https://dev.azure.com/msresearch/GCR/_wiki/wikis/GCR%20Wiki/14285/SC-ALT-Job-Submission-Configurations-and-Procedures?anchor=role-assignment-reference-tables)
   (the former may be a bit more up-to-date, while the latter is more easy to follow. Pick your poison.)
   to set up a user-assigned managed identity associated in your workspace.  Alternatively, you can use the
   [GCR bicep template](https://dev.azure.com/msresearch/GCR/_wiki/wikis/GCR%20Wiki/14815/How-to-create-Azure-Portal-Workspaces-and-role-assignments)
   to create all necessary azure resources and role assignments at once.
2. Amulet **automatically detects** the workspace’s user-assigned identity at job submission time.
   If your workspace has exactly one non-primary UAI, it will be used automatically.
   If your workspace has multiple UAIs, specify which one to use by adding its short name
   to `submit_args.env`:
   ```default
   submit_args:
     env:
       _AZUREML_SINGULARITY_JOB_UAI: my-job-identity
   ```

   You can also use the full resource ID if preferred.
3. To leverage the user-assigned identity in your job (eg using
   `DefaultAzureCredential()`), you’ll also need to `export` the
   `AZURE_CLIENT_ID` before running your python command. Take care *not* to
   add the `AZURE_CLIENT_ID` to your `submit_args.env` section.
   This step may not be required anymore at some point in the future.

### Using Shared Secrets

On **Volcano/Kubernetes**, if your cluster supports [Azure Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview),
you can use managed identity for storage and ACR access — see
[Managed Identity (Workload Identity)](basics/05_setup_targets.md#volcano-managed-identity) below.

If Workload Identity is not available, Amulet falls back to creating a SAS token
secret in the Kubernetes cluster at runtime. This secret is valid only for 7 days
(the maximum lifetime of a user delegation SAS token). If your job is queued for a
long time or runs for more than 7 days, it may be worth updating the secret by simply
submitting a new job with the same storage configured (you can remove it right after
submission). Note that the secret is tied to your identity, so if you personally lose
access to the storage account (think JIT elevation expiring), so will your job.

On **AML/Manifold**, shared secrets are discouraged, and you should use role-based access instead. If you insist (and you’re allowed to),
make sure you have the [Storage Account Key Operator Service Role](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-account-key-operator-service-role) role
so that Amulet can retrieve your secrets.
Similarly, Amulet needs you to have the Contributor role on your azure container registry (ACR) to register your ACR in the workspace for you.

The downside of this approach is that users can learn your ACR and storage account secrets directly from the workspace and can use them even if they lose access to the workspace itself.

<a id="resources"></a>

## Creating a Project

Before launching any jobs or adding targets, you must initialize a project.
For a researcher/data scientist, a project usually corresponds to a single research endeavor, e.g. a publication.

Your project provides a default storage account for your jobs.

Organizationally, *projects* contain *experiments* which contain *jobs*.

![org_hierarchy](_static/hierarchy.png)

```bash
$ amlt project create <your-project-name> <storage-account-name>
```

This will create a default container in your storage account.
To customize the container name, provide the `<container-name>` as an additional argument.
To customize the directory name in the container, add yet another `<registry-name>` argument.

The name provided for `<storage-account-name>` must be a storage account of type Storage V2, which supports Azure Tables.
See [Premium/Legacy Storage Accounts](advanced/60_premium_storage.md) how to use premium storage for your files.

Project metadata is stored in the storage account you referenced, locally a reference will be created in a file called `.amltproject`.
As long as you’re in/below a directory which contains a `.amltproject` file, Amulet will know which project you’re in – much like git.

Alternatively, you can list and checkout an existing project by running:

```bash
$ amlt project list <storage-account-name>
$ amlt project checkout <your-project-name> <storage-account-name>
```

See `amlt project --help` for more details.

### Optional: Set up a default experiment

If you often launch single jobs, you can set up a default experiment where jobs are appended to by default.
If you do not set up a default experiment, Amulet defaults to creating a new experiment for every run command.

See [Working with default experiments](advanced/0_default_experiments.md) for details.

## Compute Services

Amulet supports four compute services: AML Compute, Manifold, Volcano/Kubernetes, and Azure Batch.
We also support the [local](advanced/2_testing.md) *target*, which runs jobs interactively on the same machine **amlt** is installed on, provided all data is available locally.
Note that [not all features are supported by all services](miscellaneous/0_feature_support.md#backend-features).

<a id="access-sing"></a>

\*\*Manifold\*\*

Increasingly, compute is exposed through Manifold (formerly known as AISC and Singularity).
To submit a target to Manifold, you will need (1) a virtual cluster which allows you to access your Manifold quota through AML, and (2) an AzureML workspace.
The Manifold VCs are fetched dynamically. To see the ones you have access to, run:

```bash
$ amlt target list singularity     # or short:
$ amlt tl sing
```

Any AzureML workspace can be paired with any VC.
Consider the following commands to add workspaces and set them as default to your VCs.

```bash
$ amlt workspace add WORKSPACE_NAME
$ amlt workspace set-default VC_NAME WORKSPACE_NAME
```

```bash
$ amlt workspace set-project-default WORKSPACE_NAME
```

\*\*Azure Machine Learning (AML)\*\*

AML resources are also managed through Azure subscriptions. See [add your
own](cli_commands.md#target-management) for information on how to add targets you have access
to Amulet.

<a id="access-volcano"></a>

\*\*Volcano/Kubernetes\*\*

If your organization has set up a volcano scheduler on a kubernetes cluster, you can use it as a target in Amulet.
Amulet uses contexts as targets. The contexts and the default context are configured in your `~/.kube/config` file.
In particular, a context has a cluster, a user, and a namespace. You can try whether your context works by running `kubectl get pods`.

You can see a summary of what’s currently available in your namespace by running:

```bash
$ amlt target list volcano   # shows nodes summary, short version:
$ amlt tl 🌋
$ amlt target info volcano   # shows quota/usage, short version:
$ amlt ti 🌋
```

When submitting a job, make sure to specify the volcano queue as well if your cluster setup requires it:

```yaml
target:
  service: 🌋   # or "volcano"
  name: <your-context-name>
  queue: <your-queue-name>
```

If no explicit `queue` is set, amlt derives the queue from the job’s `sla_tier`:

- **Premium** → `<namespace>-deserved` (guaranteed resources, not preemptible)
- **Standard** → `<namespace>-opportunistic` (uses spare capacity, preemptible, will not preempt Basic tier jobs but get to run before them up to your namespace quota.)
- **Basic** → `opportunistic-cluster` (scavenges idle capacity cluster-wide, lowest priority)

If neither `queue` nor `sla_tier` is set, amlt uses the namespace name as the queue
and auto-corrects on submission failure if the cluster rejects it.

#### NOTE
If both `queue` and `sla_tier` are specified, the SLA-derived queue takes
priority. The explicit `queue` is kept as a fallback: if the SLA-derived queue
is rejected by the cluster (e.g. it doesn’t exist), amlt retries with the
explicit queue and marks the job as non-preemptible.

<a id="volcano-managed-identity-setup"></a>

**Managed Identity (Azure Workload Identity):**

If your cluster supports [Azure Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview),
you can use managed identity for storage access instead of SAS tokens.
Set these environment variables in `submit_args.env`:

```yaml
jobs:
- name: ...
  submit_args:
    env:
      # Required: ARM resource ID (recommended) or client ID (GUID)
      AMLT_VOLCANO_MANAGED_IDENTITY: /subscriptions/.../resourceGroups/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-mi
```

**Environment variables:**

- [`AMLT_VOLCANO_MANAGED_IDENTITY`](miscellaneous/70_environment_variables.md#envvar-AMLT_VOLCANO_MANAGED_IDENTITY) — ARM resource ID (recommended; enables auto-setup and full validation) or client ID (GUID; discovers existing SA by annotation).
- [`AMLT_VOLCANO_SERVICE_ACCOUNT`](miscellaneous/70_environment_variables.md#envvar-AMLT_VOLCANO_SERVICE_ACCOUNT) — Override the auto-derived ServiceAccount name, or use alone if you manage the SA and federated identity credential yourself.
- [`AMLT_USE_STORAGE_SAS`](miscellaneous/70_environment_variables.md#envvar-AMLT_USE_STORAGE_SAS) — Set to `true` to force SAS-based storage auth as a fallback.
- `AMLT_ACR_SKIP_ADMIN` — Set to `true` to skip admin ACR credentials and use short-lived refresh tokens instead.

See [Managed Identity (Workload Identity)](basics/05_setup_targets.md#volcano-managed-identity) for detailed setup instructions.

<a id="access-batch"></a>

\*\*Azure Batch\*\*

Azure Batch is a cloud-scale job scheduling service for running large-scale parallel workloads.
Unlike AML/Manifold, you manage your own Batch account and pools directly.

**Prerequisites:**

1. Install additional dependencies: `pip install azure-batch azure-mgmt-batch`
2. Create a Batch account and pool in the Azure Portal
3. Assign a user-assigned managed identity to your pool with **Storage Blob Data Contributor** role on your storage accounts

**Configuration:**

Azure Batch targets are specified directly in your YAML configuration (no `amlt target add` needed):

```yaml
target:
  service: batch
  pool: <your-pool-id>
  account_name: <batch-account-name>
  subscription_id: <subscription-id>
  resource_group: <resource-group-name>
```

All fields are required. See [Adding Workspaces](basics/05_setup_targets.md) for more details on Azure Batch configuration.

## Troubleshooting

\*\*see content\*\*

**Path lengths**

On Windows, if you encounter an error *ERROR: Could not install packages due to an EnvironmentError: [WinError 5] Access is denied:*, try to
allow [path lengths of more than 260 by modifying an HKLM key in the registry](https://www.howtogeek.com/266621/how-to-make-windows-10-accept-file-paths-over-260-characters/).

**ModuleNotFoundError: No module named ‘…’**

You likely have some installation leaking into your new environment, most often from ~/.local (via pip install –user).
Rename `~/.local/lib/pythonX.Y` to something different if it exists and try reinstalling Amulet via the commands specified above.

## Telemetry

\*\*see content\*\*

Amulet is collecting anonymized telemetry data, which is mainly intended to understand how Amulet is used,
make informed decisions for development and inform the development of AzureML tools.
Data is stripped of identifying details (targets, registries, storage account/container/workspace/resource group names, experiment + job names, etc.).
This means it is very hard to link the usage data to a concrete person or user account.
Telemetry data is retained for 30 days in azure app insights and then automatically discarded.

A unique identifier, the “installation key” is collected with the telemetry to understand
usage patterns. These keys are rotated every week, to prevent the compilation of a particular
installation’s command history for a window larger than 7 days.

If you do not wish to send telemetry, please set the environment variable `AMLT_TELEMETRY_LOGGING` to “false”.
