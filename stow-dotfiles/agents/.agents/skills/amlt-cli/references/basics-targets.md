# Adding Workspaces

To tell Amulet about workspaces you have access to, and the clusters they are attached to, use

```bash
$ amlt workspace add <wsname>
```

Amulet discovers the workspace’s resource group and subscription from its name
via Azure Resource Graph (only `Reader` on the workspace is required). Pass
`--resource-group` and `--subscription` explicitly only when the name is
ambiguous (Amulet lists the candidates in that case):

```bash
$ amlt workspace add <wsname> --resource-group <rg> --subscription <sub-id-or-name>
```

This will prompt you to add all attached clusters as Amulet targets. If you want to update them later, use `amlt workspace sync`.

# Selecting Compute Targets

To list all possible targets, run `amlt target info <service>` where `<service>` is one of `aml|sing|volcano|batch`.

In Amulet, the **target name** is used as an alias to refer to a target with all its detail information.
This detail information varies depending on the service.
The names of the targets, their real-time availability and information about their GPUs can be found using the **amlt target** commands:

```bash
# show available targets and their properties:
$ amlt target list <service>

# show available targets and their occupancy:
$ amlt target info <service>
```

where `<service>` is one of `sing|aml|volcano|batch`. On singularity, targets correspond to “VC”s (virtual clusters).

You can fix the target in your config.yaml’s target section:

```yaml
target:
  service: aml
  name: <target-name>
```

However, we recommend to just specify it at the commandline when you run a job using the `-t` option.

## Manifold Specifics

Manifold service defines workspaces as disjointed from targets and can be shown using `amlt workspace list manifold`, shortened to `amlt wl manifold`.
To specify which workspace to use, define the `workspace_name:` field in the target section, or simply use the `-w/--ws` option at CLI.

Some Manifold targets may already have a default workspace, so you do not need to specify it every time.

You can manually assign/unassign a default workspace to a targets using

```bash
$ amlt workspace set-default <mytarget> <myworkspace>
$ amlt workspace unset-default <mytarget>
```

To assign/unassign a certain default workspace to every target in a project, see

```bash
$ amlt workspace set-project-default <myworkspace>
$ amlt workspace unset-project-default
```

Note the order of priority when submitting jobs:

1. `--workspace/--ws` flag at CLI
2. Workspace field from the config file
3. User-specified target-specific default workspace
4. User-specified project-wide default workspace
5. Inherent default workspace of a target (fetched on `amlt tl sing`)

When running jobs in Manifold, you need to be aware of a few concepts:

<a id="sla-tier-description"></a>
- **SLA Tier**:
  Some jobs are granted different guarantees concerning resources. These guarantees are split in three tiers: **Premium, Standard and Basic**.
  *Premium*: jobs are guaranteed resources and your job, once running, won’t be canceled if capacity is low.
  *Basic*: jobs may run on nodes that are currently not used by Premium capacity – if such a node exists.
  *Standard* is somewhere in between the two.
  Every Manifold target comes with quotas that is divided by SLA tier.
  Make sure to run `amlt target info manifold --verbose` (abbr. `amlt ti mani -v`) to see the available quotas.
  The tier can be set at submission using the `--sla` option or in the config file.
  Please refer to the [Manifold wiki page for detailed information](https://aml-singularity.azurewebsites.net/concept/sla.html).
- **Job priority**: Within a certain SLA Tier, jobs can have different priorities, set between *High*, *Medium* and *Low*.
- **Group policy (GP)**: While a target can contain a large number of quotas, a user could get access to fewer quotas if they are part of a *group policy* for that target. Group-policy information is not fetched by default (it requires a slow per-cluster lookup); set [`AMLT_SKIP_GROUP_POLICIES`](../miscellaneous/70_environment_variables.md#envvar-AMLT_SKIP_GROUP_POLICIES) to `0` and run `amlt ti mani -v` to notice the asterisk that marks targets with restricted quotas.
  You can explicitly submit a job under a group policy using `group_policy_name` field in the target section or using `-t <VC-NAME>:<GP-NAME>`  or `-t :<GP-NAME>` when specifying a target on the command line.

  Running `amlt ti mani` will display a subcolumns under *Quotas* called **User max** when applicable. This is the quota limit you have access to for all SLAs combined.
- **FlexGPU Pilot**: Within GCR, we’re piloting a system called FlexGPU, which will allow you to exceed your group quota if there is unused premium quota.
  The affected jobs may get paused and later resumed, depending on premium quota demand.

  To opt out of the pilot, tag your job with
  ```yaml
  jobs:
  - name: myjob
    tags:
      - "FlexGPUOptOut:True"
  ```

## Volcano Specifics

Volcano has no workspace concept, and for now at least, Amulet will use the contexts defined in the kubectl config as compute targets.
As such, there’s not much to configure on the amulet side: Make sure your kubectl configuration is working.

In case you encounter broken nodes, you may want to exclude them by specifying [`AMLT_EXCLUDED_NODE_LIST`](../miscellaneous/70_environment_variables.md#envvar-AMLT_EXCLUDED_NODE_LIST) as a comma-separated list of node names.

<a id="volcano-managed-identity"></a>

### Managed Identity (Workload Identity)

If your Kubernetes cluster supports [Azure Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview),
you can use managed identity for storage access and in-container authentication,
removing the need for SAS tokens entirely. Container image pulls on Volcano
use either admin registry credentials or scoped ACR tokens (see
`AMLT_ACR_SKIP_ADMIN`).

**Prerequisites:**

1. **Create an Azure User-Assigned Managed Identity** (UAI).
2. **Assign roles** to the identity:
   - `Storage Blob Data Contributor` (or `Reader`) on each storage account your jobs access
3. **Create a Federated Identity Credential (FIC)** on the identity,
   matching the OIDC issuer of your cluster and the subject
   `system:serviceaccount:<namespace>:<service-account-name>`.
   Amulet will tell you the exact subject to use during submission.

**Enabling Workload Identity in Amulet:**

Set [`AMLT_VOLCANO_MANAGED_IDENTITY`](../miscellaneous/70_environment_variables.md#envvar-AMLT_VOLCANO_MANAGED_IDENTITY) in your job’s `submit_args.env`
to the identity’s **ARM resource ID** (recommended) or **client ID** (GUID):

```yaml
target:
  service: volcano
  name: my-context
  submit_args:
    env:
      # Recommended: ARM resource ID — enables full validation and auto-setup
      AMLT_VOLCANO_MANAGED_IDENTITY: /subscriptions/.../resourceGroups/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-mi
```

```yaml
target:
  service: volcano
  name: my-context
  submit_args:
    env:
      # Alternative: client ID (GUID) — discovers existing SA by annotation
      AMLT_VOLCANO_MANAGED_IDENTITY: 12345678-1234-1234-1234-123456789abc
```

Amulet will automatically:

- Discover an existing ServiceAccount with a matching `azure.workload.identity/client-id` annotation, or create one (with user confirmation)
- Validate the FIC and storage role assignments (when using ARM resource ID)
- Configure pods for Workload Identity

**Options:**

- [`AMLT_VOLCANO_SERVICE_ACCOUNT`](../miscellaneous/70_environment_variables.md#envvar-AMLT_VOLCANO_SERVICE_ACCOUNT): Override the auto-derived ServiceAccount name, or use alone (without `AMLT_VOLCANO_MANAGED_IDENTITY`) if you manage the SA and FIC yourself. In this mode, amlt reads the MI client ID from the SA’s `azure.workload.identity/client-id` annotation and validates the setup, but does not create or modify any resources.
- [`AMLT_USE_STORAGE_SAS`](../miscellaneous/70_environment_variables.md#envvar-AMLT_USE_STORAGE_SAS): Force SAS-based storage auth even when managed identity is configured.
- `AMLT_ACR_SKIP_ADMIN`: Skip admin ACR credentials and use the short-lived refresh token fallback instead.

## Azure Batch Specifics

Azure Batch is a standalone job scheduling service where you manage your own Batch account and pools.
Unlike AML/Manifold, there is no workspace concept—targets are configured directly in your YAML file.

**Prerequisites:**

1. Install the required packages: `pip install azure-batch azure-mgmt-batch`
2. Create an Azure Batch account and at least one pool
3. Assign a user-assigned managed identity to your pool
4. Grant the identity **Storage Blob Data Contributor** role on your storage accounts

**Target Configuration:**

Azure Batch targets are specified directly in your job configuration:

```yaml
target:
  service: batch
  cluster: <pool-id>
  vc: <batch-account-name>
  subscription_id: <subscription-id>
  resource_group: <resource-group-name>
```

All fields are required:

- `cluster`: Your Batch pool ID (case-sensitive)
- `vc`: Your Azure Batch account name
- `subscription_id`: The subscription containing your Batch account
- `resource_group`: The resource group containing your Batch account

**Storage Mounting:**

Azure Batch jobs support mounting Azure Blob Storage containers using blobfuse2.
Storage is configured the same way as AML jobs, and mounts are set up automatically
using the pool’s managed identity:

```yaml
storage:
  data:
    storage_account_name: mystorageaccount
    container_name: datasets
    mount_dir: /mnt/data
    is_output: false  # read-only with aggressive caching
  output:
    storage_account_name: mystorageaccount
    container_name: results
    mount_dir: /mnt/output
    is_output: true   # read-write
```

When running containerized jobs with storage mounts, Amulet automatically adds
Docker flags for FUSE access (`--device=/dev/fuse`, `--cap-add=SYS_ADMIN`).

#### NOTE
Azure File Shares are not yet supported for Batch storage mounting—only Blob Storage containers.

**SSH Access:**

SSH access to running Batch jobs is supported via `amlt ssh <exp> <job>`.
This creates a temporary SSH user with your public key that expires after 24 hours.

**Limitations compared to AML/Manifold:**

- No workspace concept—pools are managed directly in Azure Portal
- Job pause/resume is not supported
- Power consumption metrics are not available
- File share mounting is not yet supported

## Organization of Files on Blob Storage

By default, the code, data and results will be stored in <storage-account-name>. Results storage can be customized for each job using the yaml file.
If you want by default to save code, data and results in another storage account, see [Premium/Legacy Storage Accounts](../advanced/60_premium_storage.md).

By default, results for each job will be stored under <storage-account-name>/<container-name>/<registry-name>/amlt-results/<job-id>.
If you want to change the output format of the results, you can specify the `--output-storage-path-format` option on project create or project set.
on the output (or default) blob storage. By default, it is “{job_id}”. Another possible value is “{experiment_name}/{job_name}”. Use with care.
