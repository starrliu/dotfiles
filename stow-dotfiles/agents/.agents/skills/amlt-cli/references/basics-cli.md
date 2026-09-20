# CLI Commands

Once you have modified your code and built your configuration file, you are ready to launch the experiment.
Choose an experiment name (`<exp-name>` below) to reference all the jobs defined in the configuration file. Once pulled, the logs and
outputs for each job will be downloaded to an `<project-directory>/amlt/<exp-name>/<job-name>` directory.

\*\*Tip:\*\*

If your config file is named `amulet.yaml` and lives in the project root
(next to `.amltconfig`), you can omit it from every command.  You can also set
a custom default via `amlt project set default-config myfile.yaml`.

With your experiment name in mind, simply run:

```bash
$ amlt run                          # run all jobs (uses amulet.yaml)
$ amlt run :job1 :job2              # run specific jobs
$ amlt run :job1 my-experiment      # specific job + experiment name
$ amlt run -- --lr 0.5 --epochs 10  # pass extra arguments to your command
```

When using an explicit config file:

```bash
$ amlt run config.yaml

# if exp-name is given, the experiment will be created or jobs will be appended if it exists
$ amlt run config.yaml [<exp-name>]

# if job(s) are specified, only these will be run
$ amlt run config.yaml :job1 :job2 [<exp-name>]

# jobs can be renamed on the fly, here we rename "train" to "hopefully-better"
$ amlt run config.yaml :train=hopefully-better

# experiments can be replaced as well
$ amlt run -r config.yaml <exp-name>
```

This will start all the jobs specified in the experiment config file. You can now run the following commands to track your experiment:

```bash
# print the status of all the jobs in your experiment
$ amlt status <exp-name>

# save the stdout of each job in the experiment in the folder ``<project-directory>/amlt/<exp-name>/<job-name>`` by default
$ amlt logs download <exp-name>
# amlt logs download <exp-name> -F '*'   # fetches *all* AzureML log files

# download the content of the output folder of each job to the folder ``<project-directory>/amlt/<exp-name>/<job-name>``
$ amlt results download <exp-name>

# amlt results accepts ``-I/--include`` options which apply a filter
# to the files to be downloaded. For example,
$ amlt results download <exp-name> -I "*.pkl" -I "test/*"
# will download all the files in your model folder which have the ``.pkl`` extension,
# as well as the whole ``test`` directory. The strings passed as argument follow the
# glob pattern rules: https://pymotw.com/2/glob/
# Pulling results will overwrite existing files but will not delete them, so
# you do not have to worry about previous downloads when using ``-I``.

# cancel all the jobs present in the config file
$ amlt cancel <exp-name>

# rerun the same jobs (with potentially new code)
# rerun is very powerful, be sure to check the help
$ amlt rerun <exp-name> --upload-code
```

The `logs`, `results` and `cancel` command can be given a list of job names (each one prefixed with a colon), in which case they will only be performed on those jobs.

For example, the following command will only get the logs for job `<job-name>`:

```bash
$ amlt logs download <exp-name> :<job-name>
```

You can also track your jobs using the service’s respective portals, the URL can be found using the **amlt status** command.

Finally, you can check on your jobs, launch Tensorboards, etc, using **amlt browse**, a web frontend for most of Amulet’s functionalities:

```bash
$ amlt browse
```

#### NOTE
If your code directory is a git repo, the job will keep a reference to the commit
you used for the experiment and a diff noting which files were modified.
See [Repository snapshot](../advanced/4_repo_snapshot.md) for more details.
