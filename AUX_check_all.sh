#!/bin/bash

source config.sh

echo "CHECKING ETCD"
MASTER_PUBLIC_IP=$(az network public-ip show -g $rg -n $aksMasterLbPublicIpName --query ipAddress -o tsv)
for vmName in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].name" -o tsv | sed 's/-nic//')
do
	echo "ETCD IN $vmName"
	nicId=$(echo $vmName   | cut -d- -f4)
	ssh -p $aksMasterLbNATPortPrefix$nicId $vmUser@${MASTER_PUBLIC_IP} "sudo ETCDCTL_API=3 etcdctl member list --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/kubernetes.pem --key=/etc/etcd/kubernetes-key.pem"
	
done
echo ""

echo "CHECKING K8S MASTER COMPONENTS"
ssh -p $aksMasterLbNATPortPrefix"0" $vmUser@${MASTER_PUBLIC_IP} "kubectl get componentstatuses --kubeconfig admin.kubeconfig"
echo ""

echo "CHECKING K8S MASTER REST API"
curl --cacert ca/ca.pem https://$MASTER_PUBLIC_IP:6443/version
echo ""

echo "CHECKING K8S WORKERS"
ssh -p $aksMasterLbNATPortPrefix"0" $vmUser@${MASTER_PUBLIC_IP} "kubectl get nodes --kubeconfig admin.kubeconfig"
echo ""

echo "CHECKING REMOTE API ACCESS"
kubectl get componentstatuses
kubectl get nodes
echo ""
