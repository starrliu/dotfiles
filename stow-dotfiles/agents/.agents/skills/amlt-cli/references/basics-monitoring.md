# Monitoring

## List all the experiments in a project

Now that you have submitted some experiments, each including a few jobs, you can run:

```bash
$ amlt list [-u]
```

to print a table of all the experiments in the project, sorted by recency, along with their date, number of jobs, jobs’ statuses, and descriptions.
The displayed status information is cached, in order to update it, add `-u` to the command (it will be a bit slower if you have many jobs running).
You can also filter the experiments shown by status of their jobs. For example,

```bash
$ amlt list -s running
```

will only show experiments that have running jobs.

Note, if you have set a default experiment, this lists all the jobs in the default experiment by default. To get the list of experiments, just type:

```bash
$ amlt list [-s] -e
```

## Amulet Browser Interface

Amulet offers a browser-based GUI that covers most of its post-submission functionalities: **amlt status**, **amlt list**, **amlt logs**, etc. To access it, simply run:

```bash
$ amlt browse
```

and go to the URL displayed or to the browser window that opened automatically.

#### NOTE
If you’re using ssh to access a remote machine where you execute
Amulet, you can run **amlt browse** on the remote machine.
Then, simply use port forwarding when accessing the remote machine, for example:

`ssh -L 5000:localhost:5000 myself@my-dev-machine`

Or, in your `.ssh/config`, add this under the host:

`LocalForward 5000 localhost:5000`

After starting **amlt browse**, point your browser on your *local* machine to `http://localhost:5000`.

## Tensorboard

Amulet also allows you to monitor your jobs and experiments via tensorboard. To do so:

* Your code should write some summaries to the job’s output directory i.e. to `os.environ['AMLT_OUTPUT_DIR']`.
  The tensorflow example we have seen in [Storage](25_data.md) does this, but you can also write tensorboard files from e.g. pytorch via [TensorBoardX](https://github.com/lanpa/tensorboardX).
* Make sure that you have tensorboard installed on the computer where you’re using Amulet.
  If you installed Amulet via `pipx`, tensorboard needs to be installed in the pipx environment:

```bash
$ pipx inject amlt tensorboard
```

* Run **amlt browse**.

Then go to the URL displayed or the browser window that opened automatically, select the
experiments or jobs you want to compare and click “launch tensorboard”.
You can have multiple tensorboards open simultaneously while
**amlt browse** is running.
To switch between them, use the “Tensorboards” menu item.

Under the hood, **amlt browse** launches [TensorBoard](https://www.tensorflow.org/tensorboard) on a free port on
your machine and starts looking for any `tfevents` file located in the model
directory of your jobs. **amlt browse** sits between the tensorboard
and your browser and will proxy any requests between them.

On AML, Amulet also patches tensorboard so that when you log scalars, they can also be viewed on the AML portal and used by [HyperDrive](35_hps.md#hyperdrive-intro).

#### WARNING
On **Windows**, using long names for jobs might lead to errors in TensorBoard of the form “*No dashboards are active for the current data set*”. This can be resolved by allowing [path lengths of more than 260 by modifying an HKLM key in the registry](https://www.howtogeek.com/266621/how-to-make-windows-10-accept-file-paths-over-260-characters/).
