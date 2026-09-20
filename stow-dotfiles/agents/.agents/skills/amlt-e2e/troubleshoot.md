## Troubleshoot

1. Triage:

   ```bash
   amlt status <exp> :<job>
   amlt show <exp> :<job>
   amlt logs view -n 200 <exp> :<job>
   ```

2. Branch on backend. `amlt show` prints ready-to-run commands under `example: …` keys — copy them as-is, do not paraphrase:

   - **Volcano** — examples printed by `amlt show` (concrete `<job-id>`, namespace, and container are filled in):
     ```text
     example: describe vcjob   kubectl describe vcjob <job-id> -n <ns>
     example: pod placement    kubectl get pods -l volcano.sh/job-name=<job-id> -n <ns> -o wide
     example: describe pod     kubectl describe pod <job-id>-master-0 -n <ns>
     example: container logs   kubectl logs <job-id>-master-0 -n <ns> -c <container>
     ```
   - **AML & Manifold** — both print `az ml` examples via `amlt show`:
     ```text
     example: job details      az ml job show --name <job-id> -g <rg> -w <ws>
     example: stream logs      az ml job stream --name <job-id> -g <rg> -w <ws>
     ```
     AML also prints `example: compute status   az ml compute show --name <cluster> -g <rg> -w <ws>`.
     For Manifold, you can also SSH into a running job:
     ```bash
     amlt ssh <exp> :<job>
     ```
   - **Local** — there are no backend-native debug commands; `amlt show`
     prints none. The job ran in a Docker container in the foreground, so
     diagnose from the streamed output, the files under the run's output
     directory (`-o <dir>`), and `docker info` / `docker ps -a` to confirm
     the container ran. Re-run with `amlt run ... -t local` after fixing.

3. Common **runtime** failure causes and fixes. (For submission-time
   errors — schema, missing target, missing workspace — see *Quick start*
   step 5 instead.)

   | Symptom | Action |
   |---|---|
   | Image pull error | Fix `environment.image` (and `registry`) in the config; resubmit. |
   | OOM or eviction | Increase `sku` or reduce batch size; rerun. |
   | Quota exceeded | Use a different target, or lower SLA/priority. |
   | Code error (Python traceback) | Fix code, then `amlt rerun <exp> :<job>`. |
   | Job stuck in Queued | Check target capacity via `amlt target info <service>`. |

4. **Volcano workload-identity failures.** When a Volcano job sets
   `AMLT_VOLCANO_MANAGED_IDENTITY`, pods authenticate to Azure (storage,
   ACR) via Azure Workload Identity. Common errors and fixes:

   | Error in logs / pod events | Diagnosis | Fix |
   |---|---|---|
   | `AADSTS70021: No matching federated identity record found` | The FIC subject doesn't match the ServiceAccount amlt resolved. | Re-run `amlt run` and copy the exact `system:serviceaccount:...` subject it prints; recreate the FIC with that subject (one-time, by user or cluster admin). |
   | `AuthorizationPermissionMismatch` against storage | UAI lacks `Storage Blob Data Contributor` on the storage account | Grant the role to the UAI; wait ~1 min for propagation, then `amlt rerun`. |
   | `ImagePullBackOff` from `*.azurecr.io` | UAI lacks `AcrPull`, or admin-creds path is disabled | Either keep the registry's admin user (`environment.username`), or grant `AcrPull` to the UAI and set `AMLT_ACR_SKIP_ADMIN=true`. |
   | Pod has no Azure token at all | SA missing the WI annotations | `kubectl get sa <sa-name> -n <ns> -o yaml` — confirm `azure.workload.identity/client-id` annotation; pod must have label `azure.workload.identity/use: "true"` (amlt sets this automatically when the env var is present). |
   | `different AMLT_VOLCANO_MANAGED_IDENTITY than prior jobs` | Two jobs in the same experiment point at different UAIs | Pick one UAI for the whole experiment and set it once in the global `environment.env`. |

5. After fixing, rerun affected jobs with `amlt rerun` (see
   [recover.md](recover.md)) and wait with
   `amlt watch <exp> --json --state-file "${TMPDIR:-/tmp}/amlt-watch-<exp>.json"`
   (Windows: `%TEMP%\amlt-watch-<exp>.json`) rather than polling
   `amlt status` in a sleep loop.
