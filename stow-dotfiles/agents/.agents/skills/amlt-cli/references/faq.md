# FAQ

#### NOTE
If you are not finding an answer to your question, leave us a message on our support channel ([https://aka.ms/amulet-on-teams](https://aka.ms/amulet-on-teams)), someone will be glad to help!

## Manifold quotas

See [refresher on Manifold concepts](basics/05_setup_targets.md#sla-tier-description)

### Q. I’m seeing different quotas than my collaborator for the same target. Why?

**A.** Different users are affected by different group policies ([see the relevant docs](basics/05_setup_targets.md#sla-tier-description)).
Your group policy might have more or less quotas than others. If you believe you should have access to more quotas,
contact the administrator of your target.

### Q. On `amlt ti mani`, how should I understand the **User Max** column?

**A.** Some targets or group policies will define a maximal number of units any particular user can use.
The sum comprises of all SLA tiers put together.

#### NOTE
We are aware that the nominator of the User Max column shows up as 0. This will be fixed by Manifold.

### Q. How many quotas do my jobs **cost**?

**A.** Quotas define how many GPUs/CPUs a user has access to. A job running on `80G8-A100` will cost 8 quota units.
If I only have access to 16 Premium quota units on a certain target, `2xG8-A100` will fill these quotas.

#### NOTE
There’s a small exception with the `Dv3` series, which will show `4C3/4C7/4C15/4C30/4C60` instances.
Although they only have 3/7/15/30/60 vCPUs available, they still cost 4/8/16/32/64 units, since some vCPUs are utilized for node management.

### Q. Some rows show a **limit of 0 quotas**. What does that mean?

**A.** Targets don’t necessarily define quotas for every SLA tier.
If you are seeing `0/0`, it indicates that the group policy you are under explicitly sets the number of quotas for that certain instance series and SLA tier to 0.
If you believe you should have access to these quotas, contact the administrator of your target.

## Performance

### Q. Amulet is slow on large projects/experiments

**A.** If Amulet starts to be extremely slow on larger projects / experiments, you can play with the environment variables
[`AMLT_CACHE_TIMEOUT`](miscellaneous/70_environment_variables.md#envvar-AMLT_CACHE_TIMEOUT) and [`AMLT_CACHE_SIZE`](miscellaneous/70_environment_variables.md#envvar-AMLT_CACHE_SIZE) (see more details [here](miscellaneous/70_environment_variables.md)).

## Error messages

### Q. I’m seeing “Skipping malformed database entry”. What can I do?

**A.** This is most likely caused by your project being accessed from different Amulet versions simultaneously. Updating Amulet will solve the issue.
If the error persists, please reach out to our support channel ([https://aka.ms/amulet-on-teams](https://aka.ms/amulet-on-teams)).

### Q. How to solve “ruamel-yaml” issue at installation?

**A.** This happens when `ruamel.yaml` wasn’t installed with `pip` (but e.g. by `conda`). In that case, running the following can help:

```bash
$ pip install pip==9.0.0
$ pip install ruamel.yaml==0.16 --disable-pip-version-check
$ pip install --upgrade pip
```

### Q. How to solve MKL_THREADING_LAYER incompatibility issue?

```bash
Error: mkl-service + Intel(R) MKL: MKL_THREADING_LAYER=INTEL is incompatible with libgomp.so.1 library.
        Try to import numpy first or set the threading layer accordingly. Set MKL_SERVICE_FORCE_INTEL to force it.
```

**A.** You need to set an environment variable `MKL_THREADING_LAYER: GNU` in your job’s `submit_args.env` section.
