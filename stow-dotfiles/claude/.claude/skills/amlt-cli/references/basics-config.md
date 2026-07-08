# The Configuration File

Amulet is based on the use of a configuration file (.yaml) describing the different components of
your job submission: execution environment, code, data and jobs/hyperparameter search specification.

See the following page for exhaustive documentation: [Description of an Amulet configuration file](../config_file.md).
Some examples can also be found in our [Examples](https://maluuba.visualstudio.com/_git/philly-tools?path=%2Fexamples)
folder and can be downloaded [`here`](/_static/amlt-examples.zip).
We recommend either using one of them as a template and modifying the fields accordingly, or checking `amlt template -h`.

It is possible to use [placeholders in your config file](../config_file.md#env-var-interpolation), which Amulet will replace from your local environment.

\*\*Tip:\*\* 

Use `amlt schema show config` to look up which fields are available, their types,
and allowed values.  You can drill into specific sections — for example,
`amlt schema show config jobs.sku` or `amlt schema show config target.service`.

For autocompletion and inline validation in VS Code or other editors, run
`amlt schema add *.yaml` in your project directory.  See
[Schema / Editor Support](../config_file.md#schema-editor-support) for details.

#### NOTE
It is recommended to save your config files along with your code.
