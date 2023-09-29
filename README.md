# aws-cluster
UPI Installer script for AWS OpenShift

Git clone this repo, then download the openshift-install application into the same directory.

Execute ./install clustername to initate the process.

You will be prompted for AWS credentials, then choice of location, followed by the standard OpenShift installer questions.
Please answer for AWS, adding your own ssh and pull-secret and choice of AWS region.

The cluster will be installed.

After about 30 minutes the cluster will then add the LetsEnrypt certs, using the acme.sh toolset.

The install script currently modifies the basic install-configs by using the two files install-platform-worker and install-platform-master. These
two files ae used to modify the node sizes for workers and the control plane.

If CA cert allocation fails it maybe that you need to register with the CA to proceed for example:
./acme.sh --register-account -m user@example.com
