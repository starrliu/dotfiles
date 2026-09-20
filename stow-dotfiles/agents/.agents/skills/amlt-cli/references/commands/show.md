# `amlt show`

Show job config, status, and backend debugging info.

  Prints the YAML configuration block for each job,
  its status (if ``--status`` is specified), and backend-specific info
  for debugging (e.g. kubectl commands for Volcano, az ml commands for AML).

  Backend info is always shown and includes the service type, relevant
  identifiers (namespace, workspace, cluster), and example commands for
  investigating the job on the backend.

  Examples:

    * ``amlt show exp1 :job1 @good`` — show job config and backend info.
    * ``amlt show --status exp1 :job1`` — also include current job status.

  job names can be specified as:
    * the actual job name,
    * a pattern that matches job name(s),
    * any job tag prefixed with '@' (eg. @user_defined_tag) or
    * a unique job identifier (eg. application_0000_11)

**Parameters:**

  - `--status`: Show job status info/URLs
  - `--all`, `-a`
  - `{{EXP [JOB_REF]...} [{EXP [JOB_REF]...}]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
