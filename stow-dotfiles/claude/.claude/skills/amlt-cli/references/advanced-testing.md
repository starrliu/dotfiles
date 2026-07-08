# Testing and debugging your code

## Locally

If you’re running Linux (not WSL!), docker is installed (`sudo apt install docker`),
you have the hardware required for your job, and the data is on your computer, you can test
locally whether your job runs correctly. This might speed up your
development cycle and make the transition to Amulet smoother.

```bash
$ amlt run -t local <config-file>
```

runs the first job in a config file, regardless of whether it’s from a search or from the `jobs` list.

You can also specify a specific job in your config file, and additional arguments you want to add to it

```bash
$ amlt run -t local <config-file> :<job-name> --extra-args="--model-type fancy --n-hidden 1024" --devices all
```

Note that to use GPUs, you’ll need to tell **amlt** which devices to use.
Also note that to supply extra arguments, you need `$EXTRA_ARGS` in your command list.

If you care about the results your job is writing to [`AMLT_OUTPUT_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_OUTPUT_DIR), you can
supply a directory on your computer using `--output-dir` or `-o` that will
be mounted into the docker container. Note however, that the process in the
docker container will write these files as root, so you’ll need `sudo` rights
to delete them.

Data/storage will only be mounted into the container if a `local_dir` field is defined and the directory exists. Only local data is mounted. Make sure to download data from your storage account beforehand if needed.

#### NOTE
The `debug` below command does not support local runs (`-t local`).

#### NOTE
When running amlt inside a container where the code directory was mounted
from the host (devcontainers, for example), the `local_dir` needs to refer
to a location on the host, not the container amlt is launched in.
Use `--code-dir` to specify the host location of the code.

## Remotely

If you don’t have the hardware required for your job or need to troubleshoot issues running on AML/Manifold,
you can trigger a single job in debug mode. The standard output of the job will be streamed automatically in the terminal. To do so, run the command:

```bash
$ amlt debug <config_file> [:<job_name>]
```

If the operation is interrupted, the job will be canceled.

#### NOTE
If you wish to explore the results from the job, add the `--keep-results` flag to the command.

If your remote job hangs mysteriously, you can send a signal to it causing it to print stack traces for all jobs:

```bash
$ amlt ssh myexperiment :myjob -c 'pkill -SIGILL -f main.py'
```

You can prevent amlt from enabling the faulthandler by setting [`AMLT_NO_FAULTHANDLER`](../miscellaneous/70_environment_variables.md#envvar-AMLT_NO_FAULTHANDLER).

### Interactive

You can also use a debugger (pdb, gdb, etc.) to debug your code interactively. For instance:

- In python, use `breakpoint()` to stop the program in a specific line.
- To inspect a crashing program, run python with the `-mpdb` option, e.g.
  `python -mpdb main.py --foo bar`.

#### NOTE
If you use python `breakpoint()` to trigger breakpoints, it will be disabled by Amulet in non-interactive jobs.
However, `pdb.set_trace()`-type breakpoints will still be triggered and cause your job to fail.

After setting up the debugger in your script or config file, simply add the `--interactive` or `-i` flag:

```bash
$ amlt debug --interactive <config_file> [:<job_name>]
```

#### WARNING
To ssh into singularity nodes, you have to be on VPN/corpnet.

If your configuration file contains only one job or is a hyperparameter sweep, you do not need to specify a job name.

### Troubleshooting

* When using **amlt debug --interactive** inside a tmux session, it may fail with:
  > open terminal failed: missing or unsuitable terminal: tmux-256color

  A solution is to create a symbolic link to `/lib/terminfo/s/screen-256color` in `~/.terminfo/t/tmux-256color`
  **on the remote system**,
  e.g. by adding this line to the environment.setup section of your yaml file:
  ```bash
  environment:
    setup: |
      mkdir /lib/terminfo/s/screen-256color
      ln -s /lib/terminfo/s/screen-256color ~/.terminfo/t/tmux-256color``
  ```
* Your ssh key needs to be known at the time of submitting the job.
  It must be located in your `~/.ssh` folder, keys forwarded through
  ssh-agent are *not* supported.
* If your local run does not find GPUs, be sure to use the `--devices` option.
* If you still don’t see GPUs, be sure to install nvidia docker like this:

```bash
$ distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
$ curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
$ curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
$ sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
$ sudo systemctl restart docker
```

## SSH into a running container

To ssh into a running job, use

```bash
$ amlt ssh <experiment_name> [:<job_name>]
```

Note that this only works if you can authenticate yourself with the
ssh key that was sent to the server when you submitted the job.
During job submission, Amulet looks for the first available key in
`~/.ssh`. If no key is found, sshing is silently disabled for this job.

On singularity, ssh is only enabled when the job is declared “interactive”, eg.
by using `amlt run -i` or using `amlt debug -i`.
