# Collaborate

Internally, you can work on the same project by sharing the same storage account.
To share results or data with external collaborators, see:

* `amlt storage share <remote location>`, which allows you to create a publicly accessible URL for blobs in your storage or zipped folders in your storage.
* `amlt results share NUM_DAYS <job spec(s)>`, which allows you to share results of selected jobs with collaborators, again using a publicly accessible URL.

## Enforcing a Minimum Amulet Version

To ensure all collaborators use a compatible version of amulet, create a
`.amlt-min-version` file in the root of your repository. The file should
contain a single version string, for example:

```default
10.31.0
```

Lines starting with `#` are treated as comments. When amulet starts, it walks
up from the current directory looking for this file. If the installed version is
older than the required version, amulet will refuse to run and display an
upgrade message.

This is useful when your project configuration relies on features introduced in
a specific amulet release.
