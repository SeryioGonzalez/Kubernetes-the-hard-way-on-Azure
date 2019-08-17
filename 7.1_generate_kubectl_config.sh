#!/bin/bash

source config.sh

KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g $rg -n $aksMasterLbPublicIpName --query ipAddress -o tsv)

echo "CREATING KUBECTL CONFIG"

kubectl config set-cluster kubernetes-the-hard-way \
--certificate-authority=$caFolder/ca.pem \
--embed-certs=true \
--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

kubectl config set-credentials admin \
--client-certificate=$caFolder/admin.pem \
--client-key=$caFolder/admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
--cluster=kubernetes-the-hard-way \
--user=admin

kubectl config use-context kubernetes-the-hard-way