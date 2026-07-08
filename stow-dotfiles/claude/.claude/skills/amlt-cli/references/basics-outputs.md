# Writing Outputs

In the simplest case, simply write to the location [`AMLT_OUTPUT_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_OUTPUT_DIR) points to.

Note that there are a few subtleties here though, which you need to understand if you are writing often/large/many files.

## Background

* Every time we open a file on blob storage and `.close()` it, the whole file
  gets uploaded. This upload is *blocking*, which can slow down your job.
* If you write many files in sequence, this also means that uploads will be done sequentially,
  which may waste bandwidth.

## Amulet Workarounds

To counter the above issues, Amulet offers to use *background syncing*.
[`AMLT_DIRSYNC_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DIRSYNC_DIR) actually points to a *local* filesystem.

#### NOTE
[`AMLT_DIRSYNC_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DIRSYNC_DIR) is currently not supported on the volcano service.

In regular intervals of [`AMLT_DIRSYNC_FREQ`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DIRSYNC_FREQ) seconds (default: 30), it checks changes to
files in the folder and then copies them to the blob storage mount
location ([`AMLT_OUTPUT_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_OUTPUT_DIR)) using up to [`AMLT_DIRSYNC_THREADS`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DIRSYNC_THREADS)
threads in parallel.

Amulet copies multiple files in parallel using threads to ensure maximum
bandwidth use.

However, as a consequence, you may run out of disk space on your local disk.
In this case, consider setting [`AMLT_DIRSYNC_MOVE`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DIRSYNC_MOVE) to `true` (default: `false`),
so that files copied to blob storage get removed from local disk.
Be careful, if this option is enabled, Amulet won’t reflect in your blob if you remove a file locally
(as it won’t be able to distinguish if the local file disappeared due to a move or to a remove)

While it might be tempting to checkpoint to `$AMLT_DIRSYNC_DIR`, this is not advisable:
old checkpoints may be deleted asynchronously before new ones were written,
causing you to lose state. Keeping all checkpoints causes significant
storage use buildup and is also not advisable. For distributed jobs, only
synchronous upload gives guarantees that all jobs will be able to see the files
after a potential upload barrier.

You can filter files which you want uploaded by configuring
[`AMLT_DIRSYNC_EXCLUDE`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DIRSYNC_EXCLUDE) and [`AMLT_DIRSYNC_INCLUDE`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DIRSYNC_INCLUDE).
Both variables must contain space-separated “glob” patterns.
Amulet ignores all files matching a pattern in [`AMLT_DIRSYNC_EXCLUDE`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DIRSYNC_EXCLUDE)
*unless* it is matched by a pattern in [`AMLT_DIRSYNC_INCLUDE`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DIRSYNC_INCLUDE).
For example, to only *move* CSV files, you can set:

```yaml
jobs:
  ...
  submit_args:
    env:
      AMLT_DIRSYNC_MOVE: "true"
      AMLT_DIRSYNC_EXCLUDE: "*"
      AMLT_DIRSYNC_INCLUDE: "*.csv"
```

To manually flush the background syncer, create a file `.amlt_flush_upload`
at the root of the upload directory and (optionally) wait until it disappears.

#### NOTE
For optimal performance, you can also add a storage with the reserved name
`output` to the configuration file, which may be different from the project
storage.

## Accessing outputs

The `amlt results` commands allow you to interact (list, download, remove,…)
with the outputs created. For instance `amlt results list my_experiment` will
show you outputs and their location on blob storage.

#### NOTE
On Kubernetes/Volcano targets, the `output` storage can point to a
PersistentVolumeClaim (PVC) instead of blob storage. See
[PVC Storage (Volcano/K8s)](../advanced/62_pvc_storage.md) for details on PVC-backed outputs.
