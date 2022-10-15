#!/bin/bash

source config.sh

mkdir -p $configFolder
find $configFolder -type f -exec rm {} \;

export AZURE_K8S_MASTER_API_PUBLIC_IP=$(az network public-ip show -g $rg -n $aksMasterLbPublicIpName --query ipAddress -o tsv)

echo "CREATING K8S CONFIG FOR WORKERS"

#Worker config
aksLastWorkerIndex=$(expr $aksWorkerCount - 1)
for i in $(seq 0 $aksLastWorkerIndex)
do
	instance=$aksWorkerPrefix$i
	echo "CREATING K8S CONFIG FOR WORKER $instance"
	
	kubectl config set-cluster kubernetes-the-hard-way \
		--certificate-authority=$caFolder/ca.pem \
		--embed-certs=true \
		--server=https://${AZURE_K8S_MASTER_API_PUBLIC_IP}:6443 \
		--kubeconfig=$configFolder/${instance}.kubeconfig

	kubectl config set-credentials system:node:${instance} \
		--client-certificate=$caFolder/${instance}.pem \
		--client-key=$caFolder/${instance}-key.pem \
		--embed-certs=true \
		--kubeconfig=$configFolder/${instance}.kubeconfig

	kubectl config set-context default \
		--cluster=kubernetes-the-hard-way \
		--user=system:node:${instance} \
		--kubeconfig=$configFolder/${instance}.kubeconfig

	kubectl config use-context default --kubeconfig=$configFolder/${instance}.kubeconfig
		
done

echo "Creating K8S Kube proxy config"
kubectl config set-cluster kubernetes-the-hard-way \
	--certificate-authority=$caFolder/ca.pem \
	--embed-certs=true \
	--server=https://${AZURE_K8S_MASTER_API_PUBLIC_IP}:6443 \
	--kubeconfig=$configFolder/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
	--client-certificate=$caFolder/kube-proxy.pem \
	--client-key=$caFolder/kube-proxy-key.pem \
	--embed-certs=true \
	--kubeconfig=$configFolder/kube-proxy.kubeconfig

kubectl config set-context default \
	--cluster=kubernetes-the-hard-way \
	--user=system:kube-proxy \
	--kubeconfig=$configFolder/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=$configFolder/kube-proxy.kubeconfig

echo "Creating K8S kube-controller-manager config"
kubectl config set-cluster kubernetes-the-hard-way \
	--certificate-authority=$caFolder/ca.pem \
	--embed-certs=true \
	--server=https://127.0.0.1:6443 \
	--kubeconfig=$configFolder/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
	--client-certificate=$caFolder/kube-controller-manager.pem \
	--client-key=$caFolder/kube-controller-manager-key.pem \
	--embed-certs=true \
	--kubeconfig=$configFolder/kube-controller-manager.kubeconfig

kubectl config set-context default \
	--cluster=kubernetes-the-hard-way \
	--user=system:kube-controller-manager \
	--kubeconfig=$configFolder/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=$configFolder/kube-controller-manager.kubeconfig

echo "Creating K8S kube-scheduler config"
kubectl config set-cluster kubernetes-the-hard-way \
	--certificate-authority=$caFolder/ca.pem \
	--embed-certs=true \
	--server=https://127.0.0.1:6443 \
	--kubeconfig=$configFolder/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
	--client-certificate=$caFolder/kube-scheduler.pem \
	--client-key=$caFolder/kube-scheduler-key.pem \
	--embed-certs=true \
	--kubeconfig=$configFolder/kube-scheduler.kubeconfig

kubectl config set-context default \
	--cluster=kubernetes-the-hard-way \
	--user=system:kube-scheduler \
	--kubeconfig=$configFolder/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=$configFolder/kube-scheduler.kubeconfig

echo "Creating K8S kube-admin config"
kubectl config set-cluster kubernetes-the-hard-way \
	--certificate-authority=$caFolder/ca.pem \
	--embed-certs=true \
	--server=https://127.0.0.1:6443 \
	--kubeconfig=$configFolder/admin.kubeconfig

kubectl config set-credentials admin \
	--client-certificate=$caFolder/admin.pem \
	--client-key=$caFolder/admin-key.pem \
	--embed-certs=true \
	--kubeconfig=$configFolder/admin.kubeconfig

kubectl config set-context default \
	--cluster=kubernetes-the-hard-way \
	--user=admin \
	--kubeconfig=$configFolder/admin.kubeconfig

kubectl config use-context default --kubeconfig=$configFolder/admin.kubeconfig