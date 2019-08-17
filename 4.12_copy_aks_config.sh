#!/bin/bash

source config.sh

echo "COPYING CONFIG TO WORKERS"
for workerData in $(az network public-ip list --query "[?tags.module == 'k8sworkers'].[ipAddress, name]" -o tsv | sed 's/\t/_/')
do
	workerIpAddress=$(echo $workerData | cut -d_ -f1)
	workerIpName=$(echo $workerData    | cut -d_ -f2)
	workerName=$(echo $workerIpName | sed 's/-public-ip//')
	
	echo "COPYING CONFIG TO WORKER $workerName"
	
	scp -o StrictHostKeyChecking=no $configFolder/$workerName.kubeconfig $configFolder/kube-proxy.kubeconfig $vmUser@$workerIpAddress:~/
done

echo "COPYING CONFIG TO MASTERS"
MASTER_PUBLIC_IP=$(az network public-ip show -g $rg -n $aksMasterLbPublicIpName --query ipAddress -o tsv)
for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, ipConfiguration:ipConfigurations[0].name}" -o tsv | sed 's/\t/_/')
do
	nicName=$(echo $nicData    | cut -d_ -f1)
	nicId=$(echo $nicName      | cut -d- -f4)
	
	echo "COPYING CONFIG TO MASTER $nicId"
	
	scp -o StrictHostKeyChecking=no -P $aksMasterLbNATPortPrefix$nicId \
		$configFolder/admin.kubeconfig $configFolder/kube-controller-manager.kubeconfig $configFolder/kube-scheduler.kubeconfig \
		$vmUser@${MASTER_PUBLIC_IP}:~/
	
done
