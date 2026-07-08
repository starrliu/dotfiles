# `amlt scan-image`

Check a Docker image for vulnerabilities using Azure Defender and/or Trivy.

  The default scan mode is "Auto", which first looks for a cached Trivy scan
  artifact attached to the image in the ACR, then falls back to Azure Defender.
  FedRAMP overrides are always applied in Auto mode.

  Azure Defender automatically checks images in your ACR shortly after they are pushed.
  This script retrieves those vulnerability findings and filters them based on severity.

  Alternatively, if Trivy is selected as the scan mode, the script will perform a local scan of the image.
  You need to have Trivy installed and accessible in your system's PATH for this to work.
  Trivy scan results are automatically uploaded as OCI artifacts to the ACR for caching.

  If scan mode includes "FedRAMP", additional filtering is applied based on
  FedRAMP requirements. These may modify the severity of the vulnerabilities found by Defender/Trivy,
  as well as the due dates for fixing them.

**Parameters:**

  - `IMAGE` **(required)**
  - `--severity`: Minimum vulnerability severity to report (Critical, High, Medium, or Low) (default: `Critical`)
  - `--verbose`: Show detailed vulnerability information
  - `--scan-mode` `[None|Defender|Defender+FedRAMP|Trivy|Trivy+FedRAMP|Auto]`: Scan mode to use: Auto (cached Trivy artifact, then Defender, with FedRAMP), Defender, Defender+FedRAMP, Trivy, Trivy+FedRAMP, or None (default: `Auto`)
  - `--max-job-duration-days` `INTEGER`: Maximum expected job duration in days (default: `28`)
  - `--pull-newest`: Pull the newest image from the registry before scanning (only applies to Trivy scans)
  - `--ignore-unfixed`: Ignore vulnerabilities that do not have a fix available. Careful, this may just mean that for your OS *version*, no fix is available -- and never will be.
  - `--max-cache-age-days` `INTEGER`: Maximum age in days for cached trivy scan artifacts (Auto mode only) (default: `7`)
  - `--json-help`: Print command help as structured JSON and exit.
