# Troubleshooting

## Workspace diagnostics (AML Compute & Singularity)

If you suspect an issue with the AzureML workspace itself (e.g. networking, storage, or managed services), run the built-in workspace diagnostics:

```python
from azure.ai.ml import MLClient
from azure.ai.ml.entities import Workspace
from azure.identity import AzureCliCredential

subscription_id = "<your-subscription-id>"
resource_group = "<your-resource-group-name>"
workspace = "<your-workspace-name>"

ml_client = MLClient(AzureCliCredential(), subscription_id, resource_group)
resp = ml_client.workspaces.begin_diagnose(workspace).result()
for result in resp.application_insights_results:
    print(f"Diagnostic result: {result.code}, {result.level}, {result.message}")
```

The subscription, resource group, and workspace name can be found in `amlt show` output or in the amlt target configuration.

## Azure Batch pool scaling diagnostics

When a Batch pool in UserSubscription mode fails to scale up (0 current nodes, stuck in `resizing`), the pool itself does NOT surface the underlying errors. Check the auto-created resource groups where Batch deploys the VMSS.

1. **Get pool status** — `az batch pool show --pool-id <pool> --account-name <acct> --account-endpoint <acct>.<region>.batch.azure.com`. Check `allocationState`, `currentLowPriorityNodes` vs `targetLowPriorityNodes`, and `resizeErrors`.
2. **Find the VMSS resource groups** — For UserSubscription Batch accounts, VMs are allocated in auto-created resource groups named `AzureBatch-<guid>-C` in the same subscription. Filter by tags:

    ```bash
    az group list --subscription <sub-id> --tag BatchAccountName=<account-name> --tag PoolName=<pool-id>
    ```

3. **Check activity logs for deployment failures** — The real errors (e.g. `SkuNotAvailable`, quota exceeded) appear as failed `Create Deployment` operations in those resource groups:

    ```bash
    az monitor activity-log list --resource-group 'AzureBatch-<guid>-C' --subscription <sub-id> --offset 1h --status Failed -o json
    ```

    Parse the `properties.statusMessage` JSON to get the inner error (e.g. `SkuNotAvailable`, `OperationNotAllowed` for quota).

4. **Check subscription quotas** — For Spot/Low-Priority nodes the relevant quota is `Total Regional Low-priority vCPUs`: `az vm list-usage --location <region> --subscription <sub-id>`.

Common causes: `SkuNotAvailable` (no Spot capacity for that VM size in the region — try a different SKU or region), quota exhaustion, or Azure Policy blocking the deployment.
