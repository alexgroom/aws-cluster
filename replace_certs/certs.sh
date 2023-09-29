#! /bin/sh
export RHOCP_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
export RHOCP_WILDCARD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')

if [ -d acme.sh]
then
  cd acme.sh
elif
  git clone https://github.com/acmesh-official/acme.sh.git
  cp dns_aws.sh acme.sh/dnsapi/ 
  cd acme.sh
fi

./acme.sh --issue -d ${RHOCP_API} -d "*.${RHOCP_WILDCARD}" --dns dns_aws

sleep 2

./acme.sh --install-cert -d ${RHOCP_API} -d "*.${RHOCP_WILDCARD}" --cert-file cert.pem --key-file key.pem --fullchain-file fullchain.pem --ca-file ca.cer

ls -la 

sleep 2

oc create configmap custom-ca --from-file=ca-bundle.crt=ca.cer -n openshift-config

oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'

oc create secret tls le --cert=fullchain.pem --key=key.pem -n openshift-ingress

oc patch ingresscontroller.operator default --type=merge -p '{"spec":{"defaultCertificate": {"name": "le"}}}' -n openshift-ingress-operator

cd ..
