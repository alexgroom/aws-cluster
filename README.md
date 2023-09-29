# aws-cluster
UPI Installer helper script for OpenShift on AWS

Git clone this repo, then download the `openshift-install` application into the same directory.

Install the `aws` CLI

Install OpenShift `oc` CLI

Install a copy of `yq`

Execute `./install.sh <clustername>` to initate the process.

You will be prompted for AWS credentials (key and secret), then choice of location, followed by the standard OpenShift installer questions.
Please answer for AWS provisioning, adding your own ssh key, pull-secret and choice of AWS region.

The install script currently modifies the supplied basic `install-config.yaml` by using the two files `install-platform-worker` and `install-platform-master`. These
two files are used to modify the node sizes for workers and the control plane.

The cluster will be installed.

After about 30 minutes the cluster will then add the LetsEnrypt certs, using the `acme.sh` toolset.

If CA cert allocation fails it maybe that you need to register with the CA to proceed for example:
`./acme.sh --register-account -m user@example.com`
