## Recover

1. **Inspect before changing anything.**

   ```bash
   amlt status <exp> :<job>
   amlt show <exp> :<job>
   ```

   If the job is still running, ask before rerunning or resuming. If the
   user wants to preserve the original failed job record, use `--copy-to`
   rather than replacing in place.

2. **Choose the recovery action and explain its effect.**

   ```bash
   amlt rerun <exp> :<job>                                   # same code, replace job in place
   amlt rerun <exp> :<job> --upload-code                     # re-upload code from config.code.local_dir
   amlt rerun <exp> :<job> --copy-to <new-exp-name>          # rerun into a new experiment
   amlt resume <exp> :<job>                                  # resume a paused job
   ```

   For any action that replaces existing job state, echo the exact
   command and wait for user confirmation before running it.

3. **Watch the recovered jobs.** After any rerun or resume, wait for the
   new jobs to finish with `amlt watch` rather than polling `amlt status`
   in a sleep loop:

   ```bash
   STATE_FILE="${TMPDIR:-/tmp}/amlt-watch-<exp>.json"        # Windows: %TEMP%\amlt-watch-<exp>.json
   amlt watch <exp> --json --state-file "$STATE_FILE"
   ```

Exit code `0` = all passed, `12` = any job failed. For an interactive
check instead of waiting, use `amlt status <exp>`.
