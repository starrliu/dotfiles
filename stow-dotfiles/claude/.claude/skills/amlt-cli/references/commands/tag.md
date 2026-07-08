# `amlt tag`

Tag or untag jobs; tags can be used in place of names.

  use +tag/-tag to add/remove tags for the given job name, respectively

  Examples:

  * add tag "good" to job1, and removes tags "bad" and "broken"
    * ``amlt tag <exp-name> :job1 -- +good -bad -broken``
  * idem for jobs matching the pattern
    * ``amlt tag <exp-name> :job[123] -- +good -bad -broken``
  * add tag "passed" to all jobs with pass status
    * ``amlt tag <exp-name> --status pass +passed``

  Most other commands allow referring to tagged jobs using @ syntax, e.g.
    * ``amlt results download <experiment> @good``

  Instead of ``:<job-name>``, you can also use ``@<tag-name>``, ``:<job-id>``, or ``:<index>``
  (for example ``:-1`` for the last job).

**Parameters:**

  - `--n-workers` `INT [1<=x<=50]`: Use this many processes in parallel (default: `10`)
  - `-s`, `--status` `STATUS`: Only jobs with these status values are tagged (default: `Sentinel.UNSET`)
  - `{{EXP [JOB_REF]...} [TAGS]...}` (multiple)
  - `--json-help`: Print command help as structured JSON and exit.
