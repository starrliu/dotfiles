# `amlt watch`

Watch jobs until completion, sending desktop notifications on state changes.

  Polls job status at a configurable interval and sends a desktop notification
  when jobs reach a terminal state (pass, fail, killed, expired). Optionally
  notifies on every state transition with ``--notify transitions``.

  Use ``--grep PATTERN`` to additionally watch job logs for regex matches.

  **Agent-friendly mode**: Use ``--json`` for structured JSONL output that
  agents can parse.  Combine with ``--exit-on-grep`` and ``--state-file``
  to let agents sleep until an important event occurs, then resume::

      amlt watch exp --json --grep 'OOM' --exit-on-grep --state-file /tmp/w.json

  On Unix, send ``SIGHUP`` to trigger an immediate status check::

      kill -HUP <pid>

  Exit codes: 0 = all passed, 12 = any job failed, 13 = grep match
  (``--exit-on-grep``).

  Examples:

  * Watch all jobs in an experiment until they finish:

    * ``amlt watch my_experiment``

  * Watch specific jobs with verbose output:

    * ``amlt watch my_experiment :job1 :job2 -v``

  * Watch and alert on OOM errors in logs:

    * ``amlt watch my_experiment --grep 'OOM|out of memory' -v``

  * Watch with fast polling and all state transitions:

    * ``amlt watch my_experiment -i 30 --notify transitions``

  * Agent: fire-and-forget, wake on grep match, resume after investigating:

    * ``amlt watch exp --json --grep OOM --exit-on-grep --state-file /tmp/w.json``

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `-i`, `--interval` `INTEGER`: Poll interval in seconds. (default: `60`)
  - `--notify` `CHOICE`: Notification granularity: 'terminal' (when all jobs finish) or 'transitions' (every state change). (default: `terminal`)
  - `--grep`: Regex pattern to watch for in job logs (repeatable). Additive to status watching. (default: `Sentinel.UNSET`)
  - `-A`, `--grep-after` `INTEGER`: Lines of context after each grep match. (default: `0`)
  - `-B`, `--grep-before` `INTEGER`: Lines of context before each grep match. (default: `0`)
  - `-C`, `--grep-context` `INTEGER`: Lines of context before and after each grep match (overrides -A/-B).
  - `--json`: Emit JSONL events to stdout (agent-friendly).
  - `--exit-on-grep`: Exit with code 13 on first grep match (use with --state-file for resumable watching).
  - `--state-file` `PATH`: Path to a JSON file for persisting watcher state. Enables resumable watching after --exit-on-grep.
  - `-v`, `--verbose`: Print status to stdout each poll cycle.
  - `--no-notify`: Suppress desktop notifications (stdout only).
  - `--hide-urls`: Do not show portal URLs in output.
  - `{EXP [JOB_REF]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
