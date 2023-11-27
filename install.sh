#!/bin/sh
if [ -z $1 ]
then
  echo "install.sh <clustername> [worker replicas count, default=2]"
  exit
fi
echo Set up AWS Credentials
aws configure
echo Create basic OpenShift install config files
./openshift-install create install-config --dir $1-install-dir
#
# edit the install config to add the cluster machine sizing
#
echo Apply worker node config
yq eval -i '.compute[].platform |= load("install-platform-worker")' $1-install-dir/install-config.yaml
echo Apply master node config
yq eval -i '.controlPlane.platform |= load("install-platform-master")' $1-install-dir/install-config.yaml

if [ -z $2 ]
then
  REPLICAS=2
else
  REPLICAS=$2
fi

echo "Setting worker replica count to $REPLICAS"
yq eval -i ".compute[].replicas=$REPLICAS" $1-install-dir/install-config.yaml

echo Take a copy of the install config file
cp $1-install-dir/install-config.yaml $1-install-dir/install-config-copy

echo *********** Invoke the OpenShift installer, this will take > 30 minutes to complete *****
./openshift-install create cluster --dir $1-install-dir

echo *********** Install complete **********************
echo Now login to the cluster using oc and kubeadmin

API=$(yq eval '.clusters[].cluster.server' $1-install-dir/auth/kubeconfig)

oc login ${API} --insecure-skip-tls-verify=true -u kubeadmin -p $(cat $1-install-dir/auth/kubeadmin-password)

oc status

echo *********** Apply LetsEncrypt certs **********************

cd replace_certs
./certs.sh
cd ..

echo *********** Wait for cluster to update **********************
oc get co
