# Nextflow-API

Nextflow-API is a web application and REST API for submitting and monitoring Nextflow pipelines on a variety of execution environments. The REST API is implemented in Python using the ([Tornado](https://www.tornadoweb.org/en/stable/)) framework, and the client-side application is implemented using [AngularJS](https://angularjs.org/). Nextflow-API can be deployed locally or to a Kubernetes cluster. There is also experimental support for PBS, and Nextflow-API can be extended to other Nextflow-supported executors upon request.

## Deployment

### Local

Install the dependencies as shown in the [Dockerfile](docker/Dockerfile). Depending on your setup, you may not need to install `mongodb` or `kubectl`. You may also prefer to install the Python dependencies in an Anaconda environment:
```bash
conda create -n nextflow-api python=3.7
conda activate nextflow-api
pip install -r requirements.txt
```

Use `scripts/startup-local.sh` to deploy Nextflow-API locally, although you may need to modify the script to fit your environment.

### Palmetto

To use Nexflow-API on the Palmetto cluster, you will need to provision a Login VM, install the Python dependencies in an Anaconda environment, and either request a MongoDB allocation or use the `file` backend. Use `scripts/startup-palmetto.sh` to deploy Nextflow-API, although you may need to modify the script to fit your environment. You will only be able to access the web interface from the campus network or the Clemson VPN. For long-running deployments, run the script within a screen on your Login VM.

### Kubernetes

Refer to the [helm](helm/README.md) for instructions on how to deploy Nextflow-API to a Kubernetes cluster.

## Usage

The core of Nextflow-API is a REST API which provides an interface to run Nextflow pipelines and can be integrated with third-party services. Nextflow-API provides a collection of [CLI scripts](cli) to demonstrate how to use the API, as well as a web interface for end users.

### Backends

Nextflow-API stores workflow runs and tasks in one of several "backend" formats. The `file` backend stores the data in a single `pkl` file, which is ideal for local testing. The `mongo` backend stores the data in a Mongo database, which is ideal for production.

### API Endpoints

| Endpoint                       | Method | Description                                 |
|--------------------------------|--------|---------------------------------------------|
| `/api/workflows`               | GET    | List all workflow instances                 |
| `/api/workflows`               | POST   | Create a workflow instance                  |
| `/api/workflows/{id}`          | GET    | Get a workflow instance                     |
| `/api/workflows/{id}`          | POST   | Update a workflow instance                  |
| `/api/workflows/{id}`          | DELETE | Delete a workflow instance                  |
| `/api/workflows/{id}/upload`   | POST   | Upload input files to a workflow instance   |
| `/api/workflows/{id}/launch`   | POST   | Launch a workflow instance                  |
| `/api/workflows/{id}/log`      | GET    | Get the log of a workflow instance          |
| `/api/workflows/{id}/download` | GET    | Download the output data as a tarball       |
| `/api/tasks`                   | GET    | List all tasks                              |
| `/api/tasks`                   | POST   | Save a task (used by Nextflow)              |

### Lifecycle

First, the user calls the API to create a workflow instance. Along with the API call, the user must provide the __name of the Nextflow pipeline__. The payload of the API call is shown below.

```json
{
  "pipeline": "systemsgenetics/kinc-nf"
}
```

Then the user uploads the input files (including `nextflow.config`) for the workflow instance.

After the input and config files in place, the user can launch the workflow. The launch starts with uploading of the input files to `<id>/input` on the PVC. The jobs running as distributed pods in k8s will read the input data from here, and work together in the dedicated workspace prefixed with `<id>`.

Once the workflow is launched, the status and log will be available via the API. Ideally, higher-level services can call the API periodically to fetch the latest log of the workflow instance.

After the run is done, the user can call the API to download the output files. The output files are placed in `<id>/output` on the PVC. The API will compress the directory as a `tar.gz` file for downloading.

The user can call the API to delete the workflow instance and purge its data once done with it.

### Resource Usage Monitoring and Prediction

Nextflow-API automatically collects resource usage data generated by Nextflow, including metrics like runtime, CPU utilization, memory usage, and bytes read/written. Through the web interface you can download this data as CSV files, create visualizations, and train prediction models for specific pipelines and processes. These features were adapted from [tesseract](https://github.com/bentsherman/tesseract), a command-line tool for resource prediction.