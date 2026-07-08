# Premium/Legacy Storage Accounts

Premium storage accounts offer more performance for blob storage, but do not
offer Azure Tables storage for Amulet metadata. To use Premium
storage accounts, you have two options:

1. In “storage” section of your config.yaml, specify the premium storage account
   as a storage with name “output”. This will cause your jobs to write there instead of your
   project storage account.
2. When creating your project, specify the premium storage account:
   ```bash
   $ amlt project create <project-name> <standard-storage-account> \
     --default-blob-storage <premium-storage-account>
   ```

   This will cause all code you upload, as well as job outputs, to be automatically saved
   to the premium storage account without a need to modify the config.yaml.

If you happen to have an old “V1” storage account, table storage is also not supported.
However, [you can upgrade it](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-upgrade?tabs=azure-portal)
to a “Standard V2” blob storage account without impacting your files.
