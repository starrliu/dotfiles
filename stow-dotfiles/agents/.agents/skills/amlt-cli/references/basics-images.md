# Docker Images

Your job will be executed in a *Docker container*, which you can think of as an instantiation of a *Docker image*.

Docker images contains drivers, job dependencies, etc.
Docker images are usually *pushed to* or *pulled from* a *Docker registry*.
The Microsoft offering for registries is an Azure Container Registry (ACR).

A common *public* registry is Dockerhub (docker.com).
Dockerhub started throttling Azure in July 2022, so using images from Dockerhub is going to be slow.
Microsoft also advises not to build your images on Dockerhub images, since this poses a security risk.
In summary, **start from** [approved images](https://aka.ms/golden-images) **and push them to an ACR**.

```yaml
target:
  ...
environment:
  image: mcr.microsoft.com/mirror/nvcr/nvidia/pytorch:22.04-py3
  registry: nvcr.io
```

If possible, Amulet will try to replace your image tag with a image *digest*. This is a checksum uniquely identifying the image.
In contrast to tags like `:latest`, which can be updated to point to a different image, the digest is immutable.
This helps to ensure that your job runs with the same image every time, even if it gets preempted and restarted.
When you `amlt rerun` a job, Amulet will translate the (potentially updated) tag into a digest again.

## Volcano Specifics

We suggest you pre-install the following in your image to avoid slow or fragile
runtime installs:

- **blobfuse2** — used to mount blob storage inside pods.
- **nfs-common** — needed for NFS mounts from the blobfuse sidecar.
- **azcopy** — used for code download and result upload (required with PVC output storage).

Amulet will attempt to install missing tools at job startup, but this takes time
and may fail on minimal images.

We assume that your image is in an Azure Container Registry (ACR).
During job submission, Amulet tries the following methods to obtain image-pull
credentials, in order:

1. **AcrPullBinding (recommended)** – the cluster’s msi-acrpull controller
   automatically mints and rotates ACR tokens.  No token expiry concerns, even
   for long-queued or preempted jobs.  Requires one-time setup (see below).
2. **Short-lived refresh token (fallback)** – Amulet automatically exchanges
   the current AAD token for a short-lived ACR refresh token (~3 h).  No setup
   needed, but preempted jobs may fail to restart after the token expires.

<a id="acr-pull-binding-setup"></a>

### AcrPullBinding setup

AcrPullBinding uses Workload Identity to pull images without static credentials.
It builds on the workload SA configured via [`AMLT_VOLCANO_MANAGED_IDENTITY`](../miscellaneous/70_environment_variables.md#envvar-AMLT_VOLCANO_MANAGED_IDENTITY)
or [`AMLT_VOLCANO_SERVICE_ACCOUNT`](../miscellaneous/70_environment_variables.md#envvar-AMLT_VOLCANO_SERVICE_ACCOUNT) (see [Managed Identity (Workload Identity)](05_setup_targets.md#volcano-managed-identity)).
If any step below is missing, Amulet will detect it at submission time and print
the exact command to fix it.  The setup is:

1. A **dedicated service account** `<sa>-acr-pull` (where `<sa>` is your
   workload SA) with the `azure.workload.identity/client-id` and
   `azure.workload.identity/tenant-id` annotations.
2. A **Federated Identity Credential** on your Managed Identity with subject
   `system:serviceaccount:<namespace>:<sa>-acr-pull` and audience
   `api://AzureCRTokenExchange`.
3. The Managed Identity must have **AcrPull** role on the ACR.

That’s it — `amlt run` handles the AcrPullBinding CR and imagePullSecrets
automatically.  If the AcrPullBinding CRD is not installed on your cluster,
Amulet silently falls back to the refresh-token method.

## Manifold Specifics

Images used in Manifold can be either based from [Manifold-provided platform images](https://aml-singularity.azurewebsites.net/container_images/) or [custom images](https://singularitydocs.azurewebsites.net/docs/tutorials/custom_images/).
Make sure to read through the recommended practices.

**Platform images** can be referenced using short aliases and exist in multiple hardware-specific versions.
So if you just specify `image: amlt-sing/pytorch`, and your job only needs what’s in that image,
Manifold *should* make sure that your job will run fine on AMD or NVidia GPUs by picking the correct image based on your selected target SKU.
Currently, Manifold chooses the corresponding image at submit time, so you cannot submit to both AMD+NVidia instances simultaneously.

To specify a platform image, refer to `amlt cache base-images` to see which platform images are available.
Leave the registry and username fields empty.

```yaml
environment:
  image: amlt-sing/pytorch-1.8.0
```

When submitting with a **Custom Image** (ie. not a platform one) through Amulet, you must make sure that it has `sudo` installed and is Ubuntu-based.
You will be responsible for keeping it updated and compliant (ie, you may get S360 alerts if your image contains packages with known vulnerabilities).
You also have to make sure that the image you’re using has the right GPU drivers, and generally supports the accelerator hardware you’re targeting.
This means that they will be tied to specific hardware (eg. NVidia, AMD).
You’re encouraged to rely on platform images as much as possible.

Amulet will scan images for vulnerabilities at submission time and block when it finds FedRAMP P0 issues that need to be resolved within the next [`FEDRAMP_SCANNER_MAX_JOB_DURATION_DAYS`](../miscellaneous/70_environment_variables.md#envvar-FEDRAMP_SCANNER_MAX_JOB_DURATION_DAYS) days.
See [Image Vulnerability Scanning](../miscellaneous/3_vuln_scanning.md) for more details.

#### WARNING
Note that submitting jobs with FedRAMP P0 vulnerabilities may result in at least angry emails from the Manifold security team and potentially regulatory issues for Microsoft.

## Customizing Docker Images

You are free to use any Docker image you find on the web (again, first import it into an ACR, do not directly pull from dockerhub!).
Here we show how you can further customize an image or even build a new one.

### General requirements

You can specify any number of customization steps in your `setup` list of your environment. Amulet makes sure this
runs exactly once on every node of your job (for every job!). Example:

```yaml
target:
  ...
environment:
  image: ...
  registry: myregistry.azurecr.io
  setup: pip install dependency_x --user
```

If your setup is fancy, you can also add a `setup.sh` script in the root directory of your code.

```yaml
target:
  ...
environment:
  image: ...
  registry: myregistry.azurecr.io
  setup: . setup.sh
```

#### NOTE
If you execute a multi-process job, only one of the workers executes the setup section, and you should not assume that variables
you set in setup are also available in your job.

To run commands that modify the docker image, the `image_setup` field can be used.
The commands will be run once and the modified docker image will be cached in the AML workspace.

```yaml
target:
  ...
environment:
  image: ...
  registry: myregistry.azurecr.io
  setup: . setup.sh
  image_setup:
    - apt install foo-bar-baz
```

The image_setup step will run as root, whereas `setup` section will run with the user used for your job (root on AML, aiscuser on Manifold).

### Access to private registries

To access private registries, you can use admin-credentials or identity-based access.
To use admin-credentials (discouraged), provide a `username` field in the environment section.
On job submission, you may be prompted to enter the corresponding password.

```yaml
environment:
  image: ...
  registry: myregistry.azurecr.io
  username: johndoe@microsoft.com
```

For identity-based access, configure your workspace MSI/UAI to have AcrPull
permissions on the ACR and do *not* provide a username field.

If you used to use admin-credentials in the past, you may also have to remove
workspace connections to the ACR in your Workspace. See the “Connections” tab in the AzureML Portal.

### Fully custom image

With the options above, you can probably get any code to run. However, it might imply wasting time installing everything before each job.
For even more flexibility, you can create your own image and use either DockerHub or an Azure registry to host it.

#### DockerHub

#### WARNING
DockerHub started throttling Azure IPs and images building on non-approved dockerhub images are considered out of policy.

* Follow the first three steps on [this page](https://docs.docker.com/docker-hub/).
* Browse [DockerHub](https://hub.docker.com/) and find a base docker image to build on top off, e.g. `pytorch/pytorch:1.5.1-cuda10.1-cudnn7-devel`.
* Create a file called `Dockerfile` with some content, e.g.:

```dockerfile
FROM pytorch/pytorch:1.5.1-cuda10.1-cudnn7-devel

RUN apt-get update && apt-get install -y wget doxygen curl
RUN conda install scikit-learn cudatoolkit=10.2
ENV MUJOCO_PY_MUJOCO_PATH=/app/.mujoco/mujoco200
```

* From the folder containing `Dockerfile`, run:

```bash
$ docker build -t <username>/<reponame>:<tag> .
$ docker push <username>/<reponame>:<tag>
```

where `<username>` and `<reponame>` correspond to the names you used above.

* Reference the image you just pushed in the Amulet configuration file.

```yaml
environment:
  image: <username>/<reponame>:<tag>
  username: <username>
```

* That’s it!

#### NOTE
When using this image for the first time, Amulet will ask you for your Docker account password in order to access it.
You can also create a public repository, in which case you would not have to specify a `username` field.

#### NOTE
It is also worth considering starting from a base container image located in the [Microsoft Artifact Registry (MAR)](https://mcr.microsoft.com/) instead.
**Hint:** A complete catalog of container images in *MAR* can be found [here](https://mcr.microsoft.com/v2/_catalog).

#### Azure Container Registry

* Go to the [Azure container registry page](https://ms.portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.ContainerRegistry%2Fregistries).
* Create a registry, denoted `<registry-name>` below (steps are simpler than for a [storage account](../setup.md#storage)).
* Once the registry is created, go to its page, click on the Access keys tab and enable “Admin user”.
* Install Docker (instructions can be found in point 1 of the Quick Start tab).
* Pull a docker image you wish to use from e.g. DockerHub by running (if you already have an image locally, this step can be skipped):

```shell
$ docker pull pytorch/pytorch:1.9.0-cuda10.2-cudnn7-devel
```

* Run:

```shell
$ docker login <registry-name>.azurecr.io # use the username and password from the Access keys tab
# or, if you log in without using access keys,
$ az acr login -n <registry-name>
```

* Tag the image you previously pulled (or the local one you want to use):

```shell
$ docker tag pytorch/pytorch:1.9.0-cuda10.2-cudnn7-devel <registry-name>.azurecr.io/<reponame>:<tag>
```

In this step, you could also use the `<username>/<reponame>:<tag>` image built in the DockerHub section instead of the PyTorch one.

* Push the image:

```shell
$ docker push <registry-name>.azurecr.io/<reponame>:<tag>
```

* Use the image in your yaml file:

```yaml
environment:
  image: <reponame>:<tag>
  registry: <registry-name>.azurecr.io
```

That’s it! Obviously, you can combine the image creation from the DockerHub section with these instructions to customize an image and push it to an Azure registry.
