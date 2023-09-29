#!/bin/sh
if [ -z $1 ]
then
  echo "Need to supply a cluster name parameter"
  exit
fi
echo Set up AWS Credentials
aws configure
echo Create basic OpenShift install config files
./openshift-install create install-config --dir $1-install-dir
#
# edit the install config to add the cluster sizing
#
echo Apply worker node config
yq eval -i '.compute[] |= load("install-platform-worker")' $1-install-dir/install-config.yaml
echo Apply master node config
yq eval -i '.controlPlane.platform |= load("install-platform-master")' $1-install-dir/install-config.yaml

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
