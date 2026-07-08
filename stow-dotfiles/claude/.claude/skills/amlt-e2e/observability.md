# In-job observability — make a remote job tell you where it's stuck

Companion to [storage-and-identity.md](storage-and-identity.md) §6b.
A distributed cluster job that writes logs straight to a blob mount is
**unobservable**: blobfuse doesn't flush open files, so every log shows
0 bytes until the process exits, and you can't tell a hung job from a
slow one. Debugging blind means each hypothesis costs a full
setup+run cycle (often 20+ min). Wire these in *before* you debug, not
after — the first run with them on usually reveals the real failure.

## The four moves

**1. Unbuffer stdout.** Python block-buffers stdout when it's not a TTY,
so prints don't appear even on local disk until the buffer fills. Force
line-buffering:

```bash
export PYTHONUNBUFFERED=1
```

**2. Write per-process logs to LOCAL disk, copy to blob on close.**
blobfuse only flushes on close — so write each unit's log to local disk
(visible/tailable while running), and `cp` it to the blob *after* the
unit finishes (for durable post-mortem). Never write a long-running log
directly to the mount.

```bash
LOCAL_LOG_DIR=$(mktemp -d)
# ... per unit:
"$PY" worker.py ... > "$LOCAL_LOG_DIR/unit_${id}.log" 2>&1
cp "$LOCAL_LOG_DIR/unit_${id}.log" "$BLOB_OUT/unit_${id}.log" 2>/dev/null || true
```

**3. Cap each unit with `timeout` so one hang doesn't freeze the pool.**
A hung unit otherwise blocks its worker forever and you learn nothing.
`timeout` kills it (rc 124), and you print the tail of its log so the
stall point is captured:

```bash
timeout "$UNIT_TIMEOUT" "$PY" worker.py ... > "$llog" 2>&1
rc=$?
if [[ $rc -eq 124 ]]; then
    echo "[unit $id] TIMEOUT after ${UNIT_TIMEOUT}s — last lines:"
    tail -8 "$llog" | sed 's/^/    /'
fi
```

**4. Optionally tee live output to the job log (debug runs only).** For a
calibration/smoke run, stream each worker's output to stdout (the amlt
job log) with an identifying prefix, so `amlt log view` shows live
progress without downloading per-unit files. Gate it behind a flag and
leave it **off** for full runs (N workers interleaving is noise):

```bash
if [[ "$STREAM_LOG" == "1" ]]; then
    timeout "$T" "$PY" worker.py ... 2>&1 \
      | stdbuf -oL -eL tee "$llog" \
      | stdbuf -oL -eL sed "s/^/[w$wid g$gpu ${task}#${id}] /"
    rc=${PIPESTATUS[0]}
fi
```

The prefix should encode *what you're trying to verify* — here worker id,
**GPU id**, task, seed — so the job log doubles as proof of correct
work/GPU assignment, not just progress.

## Reading a job that's still in setup vs running

- **`amlt status <exp>`** → DURATION + state. `preparing`/`queued` = not
  on a node yet; `running` < ~20 min usually = still in `pip install` /
  compile, not your code. Don't diagnose your script until setup clears.
- **`amlt log view <exp> :<job> -n N`** → grep for *your* markers
  (server-healthy, queue size, the `[w.. g..]` prefixes, per-step lines).
  Their presence/absence tells you which stage it reached.
- **The real blob** (not the fuse mount) for output artifacts — see
  storage-and-identity.md §6.
- **`amlt`-provided SSH.** If submission prints
  `Providing ... .pub for ssh login`, the job is SSH-able. For a
  genuinely stuck process, that's the escape hatch: SSH in and
  `py-spy dump` / `nvidia-smi` the live process instead of guessing.

## Smoke-gate discipline

- Gate any large run behind a **tiny smoke** (1 unit × a couple
  iterations) that exercises the whole pipeline end-to-end.
- Make each unit **idempotent** (skip if its output already exists) so
  re-runs are cheap and resumable.
- Advance **one stage per iteration** — env setup, then service health,
  then first real unit — and read the log at each gate.
- Monitor with a **recurring check** (out-of-band poll), not a blocking
  wait, so you're not holding the session while a 20-min setup runs.
