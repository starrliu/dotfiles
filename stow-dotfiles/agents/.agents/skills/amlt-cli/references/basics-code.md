# Prepare your Code

Amulet handles all the data and code movements required to run your jobs on the clusters.
It also allows to easily download files the jobs wrote with very minor modifications to your existing codebase:

* The data can be accessed from your code under the [`AMLT_DATA_DIR`](../miscellaneous/70_environment_variables.md#envvar-AMLT_DATA_DIR) environment variable.
  All you have to do in your code is load from the folder `os.environ['AMLT_DATA_DIR']` to access the different files from your data folder (see below for more details).
  You may also specify the mount path manually in your config file and use it directly in your code.
  See [Description of an Amulet configuration file](../config_file.md) for details and [Multi-storage use](../advanced/61_multi_storage_configuration.md) for examples.
* To save models, checkpoints, TensorBoard files, etc, simply write to the folder `os.environ['AMLT_OUTPUT_DIR']`.
  The output files can then be accessed with the **amlt results** command described below.

[This sample code](https://maluuba.visualstudio.com/_git/philly-tools?path=%2Fexamples%2Fmnist_pytorch%2Fsrc%2Fmain.py) shows how a script might read and write data using Amulet.

Once your code is adapted (and contained in a single folder), simply add the path to that folder in your configuration file.
It will automatically be uploaded before job submission, e.g.:

```yaml
code:
  local_dir: $CONFIG_DIR/examples/mnist_pytorch/src
```

where Amulet will replace `$CONFIG_DIR` with the folder where the yaml file is located.

## Selective Code Upload

You can choose which files and subfolders Amulet uploads by adding a `.amltignore` file to your code directory (i.e., `code.local_dir`) and/or its subdirectories, that works like `.gitignore` files.
It contains one pattern per line, which is applied recursively. E.g. `*.dat` ignores all files ending in `.dat` in your project.
For more details, see [the git documentation](https://git-scm.com/docs/gitignore#_pattern_format).

In some cases, it may be better to specify which files are part of the code as
part of the YAML file, e.g. if depending on the job, different parts of a
monorepo can be skipped for uploading:

```yaml
code:
  local_dir: $CONFIG_DIR/../../..   # root folder of a lot of projects
  ignore:
  - projects/*
  - "!projects/foo"
  - "!projects/bar"
```

The `ignore` patterns are prepended to the `.amltignore` file if it exists.

Use `amlt code not-ignored config.yaml` to see which files will be uploaded and how much space will be used.
