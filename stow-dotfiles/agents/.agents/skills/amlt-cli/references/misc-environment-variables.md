# Environment variables

## Local

You can set the following environment variables on the machine where you execute Amulet to alter how Amulet is executed:

### AMLT_PROJECT_DIR

You can point this to the directory containing your `.amltconfig` if you need to work from a folder outside your project.
If not set, Amulet will look into all parents of your current directory to find a `.amltconfig` file.

### AMLT_DEFAULT_SERVICE

This variable will autofill your service in the `amlt target info` and `amlt target list` commands. For more information please visit [Service selection](../advanced/3_service_selection.md).

### SERVICE_PRINCIPAL_TENANT_ID

When automating Amulet, this can be used to authenticate with azureml without prompting for user credentials.

### SERVICE_PRINCIPAL_ID

See SERVICE_PRINCIPAL_TENANT_ID.

### SERVICE_PRINCIPAL_PASSWORD

See SERVICE_PRINCIPAL_TENANT_ID.

### AMLT_CACHE_TIMEOUT

How long Amulet remembers cached database instances, in seconds, default is 120. This is an in-memory cache,
thus be careful with large values when using with `amlt browse` in addition to CLI/other computers.

### AMLT_CACHE_SIZE

How many instances from the database to remember in the cache. Defaults to 20000.

### AMLT_ENABLE_SSH

If set to “true” (default), Amulet will set up ssh for all jobs *if* it finds an ssh key on your system.

### AMLT_LOGS_SHOW_AML_SETUP

If set to “true”, logs that are displayed or downloaded will include AML setup logs.

### AMLT_MUTE_ACR_TOKEN_WARNING

If set to “true”, mutes the ACR token expiration warning.

### AMLT_MAX_RUN_ID_LEN

Maximum length of a job name (formerly run ID) on azureml. This can vary depending on the cluster. (default: 233)

### AMLT_NO_KEYRING_CACHE

If set to “true” (default), do not use the keyring (eg. gnome-keyring, windows secrets store) to store cached azure token between amulet runs.

### AMLT_THEME

Force the terminal color scheme to `dark` or `light`. By default, Amulet
auto-detects the terminal background using a sequence of probes (OSC 11
query, OS dark-mode preference, `COLORFGBG` environment variable) and
falls back to `dark` when detection is inconclusive.

Set this when auto-detection does not work for your terminal or when you
want deterministic output, e.g. in CI or when piping to a file.

### AMLT_JSON_TABLES

If set to a truthy value (`1`, `true`, `yes`), print JSON instead of human-readable tables.
Equivalent to passing `--json-tables` on the command line. Implies `--quiet`.

### AMLT_SSH_KEY_PATH

If set, Amulet will use the designated SSH key to connect to computes for `amlt debug -i` and `amlt ssh`.

### AMLT_CODE_CHECKSUM_SECS

If Amulet finds an existing code snapshot with identical files, it can skip the code upload. To do this, it has to compute a
checksum over your files. To avoid wasting a lot of time, the checksum computation will be canceled after
AMLT_CODE_CHECKSUM_SECS seconds and Amulet will just upload the code. Default is 2 seconds, 0 disables the checksum computation
completely.

### AMLT_SING_INSTALLER_TAG

By default, Amulet uses the newest available Manifold installer/validator
tag. Sometimes there are issues with the installer and you have to use an
older version. This environment variable overrides the default.

### AMLT_SING_VALIDATOR_TAG

See `AMLT_SING_INSTALLER_TAG` above.

### AMLT_NO_BATCH_STATUS_API

Skip batch status API, will only rely on the slower service-specific (non-batched) status API.
Added for debugging purposes, or when the API is unstable/unavailable.
Setting this to “true” might also be useful when you are exclusively checking the status of individual jobs.

### AMLT_SKIP_BLOB_VERIFY

Skip verifying that the blob storage exists before submitting to AML.
This is useful when you are submitting to a private blob storage
that is not accessible from the internet.

### AMLT_SKIP_IMAGE_CHECK

Skip the pre-submit image existence check for Volcano and Batch.
Set to a truthy value (for example `1`) to bypass the check when
the image is being pushed concurrently or registry digest lookups are unreliable.

### AMLT_SKIP_GROUP_POLICIES

Controls whether Singularity (Manifold) target discovery fetches group-policy quota
information. Each virtual cluster requires a separate, often slow ARM call to its
`groupPolicies` sub-resource, which dominates the time of commands like
`amlt target list` and `amlt target info`.

Defaults to true (group policies are **skipped**), so only the account-level virtual
cluster quotas are shown. Set to a falsy value (for example `0`) to fetch group-policy
quotas and display the group-policy indicator/asterisk in `amlt ti -v`.

### AMLT_TRY_USING_HYPERDRIVE

If set to true (default), Amulet will attempt to convert non-hyperdrive “search” experiments into HyperDrive search experiments.

### AMLT_SKIP_GIT_INFO

If set to true (default is false), Amulet will not run git diff before submitting. This can be helpful on large repositories.

### FEDRAMP_SCANNER_SCAN_MODE

How images in azure container registries are scanned for vulnerabilities before job submission.
Possible values are None, Defender, Trivy, Defender+FedRAMP, Trivy+FedRAMP.
Default is Defender+FedRAMP for Manifold, and None everywhere else.

### FEDRAMP_SCANNER_MAX_JOB_DURATION_DAYS

Override how long jobs are expected to run for the purpose of vulnerability
scanning. If a vulnerability is found that is expected to be fixed in a time
frame shorter than the job duration, the job submission will be blocked.
Default is 28 days.

### FEDRAMP_SCANNER_SEVERITY

Vulnerability severity that will block job submission if found in the scan results.
Possible values are: Critical, High, Medium, Low, Informational.
Default is “Critical”. FedRAMP priorities are mapped to these levels as
well, so when `FEDRAMP_SCANNER_SCAN_MODE` includes “FedRAMP”, Critical corresponds to P0,
High to P1, and so on.

## Remote Read-Only

These environment variables will be found on the machine where your jobs execute:

### AMLT_LOGS_DIR

This variable is set by Amulet, logs written there are regularly synced to AML portal and your blob storage.

### AMLT_DIRSYNC_DIR

This variable is set by Amulet to a location on the job’s *local disk*. It is uploaded to [`AMLT_OUTPUT_DIR`](#envvar-AMLT_OUTPUT_DIR) in the background.
See [Writing Outputs](../basics/22_outputs.md) for details.

### AMLT_OUTPUT_DIR

This variable is set to a location on your blob storage. See [Writing Outputs](../basics/22_outputs.md) for details.
Use `amlt results` to retrieve any results from this location.

### AMLT_DATA_DIR

This variable is set by Amulet to the `data.remote_dir` location defined in your configuration file (also see [Storage](../basics/25_data.md) on ways to use it).

### AMLT_JOB_NAME

This variable is set by Amulet to the job name from your config file.

### AMLT_EXPERIMENT_NAME

This variable is set by Amulet to the experiment name you launched your job from.

### AMLT_DESCRIPTION

This variable is set by Amulet to the description of the experiment you launched your job from.

### AMLT_CODE_GIT_SHA

If your code is under git control, this is the latest commit hash.

### AMLT_MAP_INPUT_EXP_NAME

Inside a `map` job, refers to the name of the experiment the input job came from.

### AMLT_MAP_INPUT_JOB_NAME

Inside a `map` job, refers to the name of the input job.

### AMLT_AZUREML_MAP_RUN_ID

Inside a `map` job, refers to the azureml Run ID of the input job. This can be used eg to log to the same mlflow run.

### SUDO

Expands to “sudo” on singularity and nothing on aml compute. Use it before commands that need root privileges.

### AMLT_SERVICE

Set to aml/sing/batch/volcano/local depending on the target service. This is exported
on every backend, so you can use it to detect at runtime whether a job is running
locally (`amlt run -t local`) and branch a single config between cloud and local execution.

### AMLT_PROJECT_NAME

This variable is set by Amulet to the name of the project you launched your job from.

## Submit args

Set these environment variable in your [submit_args.env](../config_file.md#submit-args-env) section to alter how the job will be executed by AML/Manifold:

### AMLT_DOCKERFILE_TEMPLATE

If this is not set, if you submit to Manifold using a non-base image, Amulet will submit a dockerfile on your behalf to AzureML which will
run the Manifold installer and validator on your image. This ensures that the image is compatible with Manifold.
However, if you prefer to run installer and validator manually, you can set
`amlt_dockerfile_template` to “default” in your [submit_args.env](../config_file.md#submit-args-env) section.
this will create a stub dockerfile without any adaptations or checking.
this will still incur some environment build time for downloading/uploading the image, but it is safer *if you override tags* (eg “:latest”).
singularity caches images based on the tag, not the digest. if you are sure
that you are using a new tag for every push of your already
singularity-adapted image, you can also set `amlt_dockerfile_template` to “none”.
this will avoid sending a dockerfile altogether and there shouldn’t be any environment build time.

### DATASET_MOUNT_...

(Manifold) By default, the data that is read from mount is cached in blocks; 32 blocks of 2MB are cached sequentially from files that are being read
(set `DATASET_MOUNT_READ_BUFFER_BLOCK_COUNT` or `DATASET_MOUNT_READ_BLOCK_SIZE` to change these numbers).
By setting `DATASET_MOUNT_BLOCK_BASED_CACHE_ENABLED='false'`, you will disable this behavior and instead cache files that are fetched whole,
as soon at they are accessed. This is the prefered approach to access many files randomly.
See [the relevant docs](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-read-write-data-v2?view=azureml-api-2) for more details.

### AMLT_DIRSYNC_FREQ

Changes how often (in seconds) Amulet checks for new files the job wrote and uploads them to blob storage. Default is 30.

### AMLT_DIRSYNC_MOVE

If set to `true`, files copied to blob storage are removed from the job’s local disk to preserve space.

### AMLT_DIRSYNC_EXCLUDE

Space-separated list of patterns to exclude from uploading to blob storage.

### AMLT_DIRSYNC_INCLUDE

Space-separated list of patterns to include from uploading to blob storage *despite* being matched by [`AMLT_DIRSYNC_EXCLUDE`](#envvar-AMLT_DIRSYNC_EXCLUDE).

### AMLT_DIRSYNC_THREADS

An integer indicating how many threads to use at most in parallel for background file syncing.

### AMLT_NO_RUNTIME_DEPS

If set to true, Amulet will not install any runtime dependencies before running your job. The two features most likely impacted by this are

1. HyperDrive jobs in Amulet can rename themselves. This feature requires the `azure-identity` and `python-dateutil` packages.
2. Amulet patches pytorch’s tensorboard stub so that flushes result in files being uploaded to blob storage.
   This feature requires the `wrapt` package.

### AMLT_NO_FAULTHANDLER

If set to true, Amulet will not install a [faulthandler](https://docs.python.org/3/library/faulthandler.html)
in jobs running on AML/Manifold.

### AMLT_PERSISTENT_VOLUME_NAME

If set, on a volcano job, will mount the persistent volume claim (e.g. an already configured cluster-local NFS) with this name at /data.

### AMLT_PERSISTENT_VOLUME_MOUNT_DIR

If set together with [`AMLT_PERSISTENT_VOLUME_NAME`](#envvar-AMLT_PERSISTENT_VOLUME_NAME), will mount the persistent volume claim at this location instead of /data.

### AMLT_EXCLUDED_NODE_LIST

If set, on a volcano job, will exclude the nodes in this comma-separated list from being scheduled on.

### AMLT_VOLCANO_MANAGED_IDENTITY

Enables Azure Workload Identity on Volcano jobs. Set this in `submit_args.env` to either:

- An **ARM resource ID** (recommended): `/subscriptions/.../userAssignedIdentities/my-mi`
- A **client ID** (GUID): `12345678-1234-1234-1234-123456789abc`

Amulet auto-detects the format, creates/updates the Kubernetes ServiceAccount, and validates
the Workload Identity setup. See [Managed Identity (Workload Identity)](../basics/05_setup_targets.md#volcano-managed-identity) for full setup instructions.

### AMLT_VOLCANO_SERVICE_ACCOUNT

Override the auto-derived ServiceAccount name when using [`AMLT_VOLCANO_MANAGED_IDENTITY`](#envvar-AMLT_VOLCANO_MANAGED_IDENTITY),
or use standalone to point at a manually created ServiceAccount annotated with
`azure.workload.identity/client-id`. See [Managed Identity (Workload Identity)](../basics/05_setup_targets.md#volcano-managed-identity) for details.

### AMLT_USE_STORAGE_SAS

Force SAS-based storage authentication on Volcano even when
[`AMLT_VOLCANO_SERVICE_ACCOUNT`](#envvar-AMLT_VOLCANO_SERVICE_ACCOUNT) is configured. Set to `true` as a fallback if
Workload Identity is not working as expected.

### \_AZUREML_SINGULARITY_JOB_UAI

User-assigned managed identity to use in Manifold jobs. Allows the job to authenticate
to Azure resources (storage, key vault, etc.) using this identity.

Amulet auto-detects the identity when the workspace has exactly one non-primary UAI.
If the workspace has multiple UAIs, specify which one to use. You can provide either
the short name (e.g., `my-job-identity`) or the full Azure resource ID.

### AMLT_COPILOT_SKILL

If set to `false`, Amulet will not auto-install the GitHub Copilot skill to `~/.copilot/skills/amlt-cli/`.
By default, Amulet installs and updates the skill automatically when `~/.copilot/` exists.

The skill provides Copilot with a reference of all `amlt` CLI commands and documentation.
It is version-stamped and only updated when the `amlt` version changes.

You can also manage skills manually:

- `amlt agent skill install copilot` — install the skill for Copilot
- `amlt agent skill install claude` — install the skill for Claude
- `amlt agent skill clear copilot` — remove the Copilot skill and prevent auto-reinstall
- `amlt agent skill clear claude` — remove the Claude skill

Running `amlt agent skill clear copilot` leaves a marker that prevents Copilot auto-install from re-creating the skill.
Running `amlt agent skill install copilot` removes that marker and re-installs.
