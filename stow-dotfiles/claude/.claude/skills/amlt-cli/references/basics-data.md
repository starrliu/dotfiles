# Storage

The `storage` section of your configuration file defines where your
experiment data lives: input datasets, job outputs, and any other blob
containers or volumes your jobs need to access.

By default, Amulet uses your **project storage account** for everything (code
upload, metadata, results). You only need a `storage` section when you want to
read from or write to additional locations.

## Basic Usage: One Extra Storage

To mount an additional blob container (e.g. a shared dataset), add an entry
with any name you choose:

```yaml
storage:
  shared_data:
    storage_account_name: teamdatastorage
    container_name: datasets
    is_output: false          # read-only mount
```

Inside your job, the container is available at `/mnt/shared_data/` (the
mount path defaults to `/mnt/<storage_id>`). You can override it with
`mount_dir`:

```yaml
storage:
  shared_data:
    storage_account_name: teamdatastorage
    container_name: datasets
    mount_dir: /mnt/my_datasets
    is_output: false
```

\*\*Tip:\*\* 

Set `is_output: false` for read-only data sources. This mounts the
container read-only on Singularity/AML Compute, preventing accidental
writes.

### Uploading and managing data

`amlt storage` commands operate on the **project blob storage** (the storage
account and container of your current project). Upload data to it:

```bash
$ amlt storage upload data/ my_remote_dir/
```

List and remove files:

```bash
$ amlt storage list my_remote_dir/
$ amlt storage remove my_remote_dir/
```

To target a **named storage** from your config file, use `--storage-id`.
If an `amulet.yaml` exists (or a default config is set via
`amlt project set default-config`), it is used automatically — no `-c`
needed:

```bash
$ amlt storage upload --storage-id shared_data data/ remote/
$ amlt storage list --storage-id shared_data remote/
```

You can still pass `-c` explicitly to use a different config file.

## Controlling where outputs go

By default, [`AMLT_OUTPUT_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_OUTPUT_DIR) and [`AMLT_LOGS_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_LOGS_DIR) point to
Amulet-managed directories on your project storage. To write results to a
**different** blob storage account (e.g. a premium/SSD-backed one for
performance), define a storage named `output`:

```yaml
storage:
  output:
    storage_account_name: premiumstorage
    container_name: results
```

Amulet automatically creates job-specific subdirectories on the `output`
storage and [`AMLT_OUTPUT_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_OUTPUT_DIR) will point there. The `amlt results`
and `amlt logs` commands continue to work transparently.

#### WARNING
Amulet manages creation and deletion of [`AMLT_OUTPUT_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_OUTPUT_DIR)
directories. They are deleted when you run **amlt remove**.

## Combining multiple storages

You can define as many storages as needed. Each gets mounted into the
container:

```yaml
storage:
  output:
    storage_account_name: premiumstorage
    container_name: results
    mount_dir: /mnt/output
  training_data:
    storage_account_name: teamdata
    container_name: imagenet
    mount_dir: /mnt/imagenet
    is_output: false
  checkpoints:
    storage_account_name: teamdata
    container_name: checkpoints
```

In your job:

* `AMLT_OUTPUT_DIR` → Amulet-managed path under `/mnt/output/`
* `/mnt/imagenet/` → read-only training data
* `/mnt/checkpoints/` → writable checkpoint storage

## Storage fields reference

| Field                  | Required   | Description                                                               |
|------------------------|------------|---------------------------------------------------------------------------|
| `storage_account_name` | yes\*      | Azure Storage account name.                                               |
| `container_name`       | yes\*      | Blob container to mount. Mutually exclusive with `file_share_name`.       |
| `file_share_name`      | no         | Azure File Share to mount (mutually exclusive with `container_name`).     |
| `pvc_name`             | no         | PersistentVolumeClaim name (Volcano/K8s only; replaces blob fields).      |
| `mount_dir`            | no         | Custom mount path (default: `/mnt/<storage_id>`).                         |
| `is_output`            | no         | `true` (default) = read-write; `false` = read-only mount.                 |
| `datastore_name`       | no         | Use a pre-registered AzureML datastore instead of `storage_account_name`. |
| `mount_options`        | no         | List of blobfuse mount options (partial AML support).                     |
| `local_dir`            | no         | Maps to a local directory for `amlt run -t local`.                        |

\* Not required when using `pvc_name` or `datastore_name`.

<a id="storage-service-specifics"></a>

## Service-specific notes

### AML Compute / Singularity

* `is_output: false` mounts the datastore as read-only.
* `mount_options` only supports `--file-cache-timeout-in-seconds=...`; other
  options are silently ignored by AzureML.
* For **sequential** data access (streaming), set
  `DATASET_MOUNT_BLOCK_BASED_CACHE_ENABLED` to `true` in your
  [submit_args.env](../config_file.md#submit-args-env) section for faster startup and lower
  disk use. See [Azure docs on mount settings](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-read-write-data-v2?view=azureml-api-2&tabs=python).

<a id="volcano-data"></a>

### Volcano / Kubernetes

Volcano clusters typically run outside Azure, so every read/write to Azure Blob
Storage incurs egress costs and latency. **Prefer PVC storage** for data that
stays on the cluster (results, logs, shared datasets) and reserve blob access
for code download and occasional data transfers.

**Recommended setup**: Point `output` at a PVC so results and logs stay
on-cluster. This also eliminates the NFS sidecar container (see below),
reducing resource overhead and startup time:

```yaml
storage:
  output:
    pvc_name: workspace-pvc
    mount_dir: /mnt/output
```

See [PVC Storage (Volcano/K8s)](../advanced/62_pvc_storage.md) for the full PVC reference.

**Accessing blob storage via azcopy**: With managed identity, `azcopy`
authenticates automatically via workload identity
(`AZCOPY_AUTO_LOGIN_TYPE=WORKLOAD`, set by Amulet). You can call `azcopy`
directly if you know the storage account and container:

```yaml
command: |
  azcopy copy "https://myaccount.blob.core.windows.net/mycontainer/data/" ./local --recursive
```

Amulet also provides a `blob_url` helper that constructs authenticated URLs
for storages declared in your config’s `storage:` section:

```yaml
command: |
  . /mnt/amlt-scripts/blob-url
  azcopy copy "$(blob_url path/to/data my_storage)" ./local_data --recursive
```

`blob_url <path> <storage_id>` returns a full blob URL. The `storage_id`
must match a named storage from your config (e.g. `my_storage`, `default`).

**Blobfuse mounts**: By default, Amulet mounts blob containers as POSIX
filesystems using `blobfuse2`. Storages declared in the `storage:` section
are available at `/mnt/<storage_id>/` (or `mount_dir` if set). How
blobfuse is deployed depends on how much of the node your job uses:

* **Whole-node GPU jobs** (requesting all GPUs on the node): blobfuse runs
  directly in the main container (privileged mode). No extra sidecar or
  dependencies needed — just pre-install `blobfuse2` in your image for
  faster startup.
* **Partial-node GPU jobs and CPU jobs**: An NFS sidecar container runs
  `blobfuse2` + NFS-Ganesha and exports the mounts to the main container
  via NFS. This avoids granting the main container privileged access (which
  would be unsafe on a shared node), but adds overhead:
  * ~500m CPU, ~6Gi memory for the sidecar
  * `nfs-common` (or `nfs-utils` on RHEL/Fedora) must be in your image
    (Amulet installs it at runtime if missing, delaying startup)
  * NFS mount readiness wait (~5-10s)

When the `output` storage is PVC-backed and no other blob storage needs
write access, the sidecar is **skipped automatically** — code is downloaded
via `azcopy` instead.

**Read-only data PVCs**: You can also mount additional PVCs for shared datasets:

```yaml
storage:
  my_data:
    pvc_name: shared-datasets
    mount_dir: /mnt/data
    is_output: false
```

## Authentication

Amulet uses **identity-based access** for storage. The managed identity of the
compute must have the **Storage Blob Data Contributor** role on the storage
account. No secrets or keys are needed — this is the default behavior.

#### NOTE
On Volcano/Kubernetes targets, managed identity is auto-detected from the
`AMLT_VOLCANO_MANAGED_IDENTITY` or `AMLT_VOLCANO_SERVICE_ACCOUNT`
environment variables in your target config. No `identity: managed` field
is required.

#### NOTE
The following legacy credential methods are deprecated and will be removed
in a future release:

* `amlt cred storage set` (credential store)
* `AZURE_STORAGE_ACCESS_KEY_<storage_account_name>` environment variable
* Automatic storage account key retrieval
* User-delegation SAS tokens on Volcano/Kubernetes targets

#### NOTE
If your code is under git version control, your current branch, commit,
and uncommitted changes are [saved in the experiment directory](../advanced/4_repo_snapshot.md).
