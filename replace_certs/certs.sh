#! /bin/sh
export RHOCP_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
export RHOCP_WILDCARD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')

echo "API URL" $RHOCP_API
echo "Wildcard URL" $RHOCP_WILDCARD

if [ -d acme.sh ]
then
  echo "Deleting any existing cert environment so we start clean"
  echo "Note also that acme.sh creates files here in the ~/.acme.sh directory"
  echo "This script does not clean these an instead assumes each run uses a different cluster name"
  rm -rf acme.sh
fi

git clone https://github.com/acmesh-official/acme.sh.git
cp dns_aws.sh acme.sh/dnsapi/ 
cd acme.sh

./acme.sh --issue -d ${RHOCP_API} -d "*.${RHOCP_WILDCARD}" --dns dns_aws

sleep 2

./acme.sh --install-cert -d ${RHOCP_API} -d "*.${RHOCP_WILDCARD}" --cert-file cert.pem --key-file key.pem --fullchain-file fullchain.pem --ca-file ca.cer

ls -la 

sleep 2

echo "Inserting the new certifictaes into the cluster"
echo "If any of these artefacts already exist (from a previous failed attempt), then you will need to manually"
echo "delete the le secret and custom-ca configmap before re-using this script"

oc create configmap custom-ca --from-file=ca-bundle.crt=ca.cer -n openshift-config

oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'

oc create secret tls le --cert=fullchain.pem --key=key.pem -n openshift-ingress

oc patch ingresscontroller.operator default --type=merge -p '{"spec":{"defaultCertificate": {"name": "le"}}}' -n openshift-ingress-operator

cd ..
