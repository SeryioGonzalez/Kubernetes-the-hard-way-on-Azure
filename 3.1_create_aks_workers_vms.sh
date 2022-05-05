#!/bin/bash

source config.sh

module="k8sworkers"

aksLastWorkerIndex=$(expr $aksWorkerCount - 1)

echo "Creating av-set for worker VMs"
az vm availability-set create -g $rg -n $avSetAksWorkersName --tags module=$module

export AZURE_K8S_WORKER_VM_AV_SET_ID=$(az vm availability-set show -g $rg -n $avSetAksWorkersName --query id -o tsv)
export AZURE_APP_VM_SUBNET_ID=$(az network vnet subnet show -g $rg --vnet $vnetName --name $subnetName --query id -o tsv)

for i in $(seq 0 $aksLastWorkerIndex)
do
	echo "Creating K8S Worker $i"
	vmName=$aksWorkerPrefix$i
	az deployment group create --no-wait --resource-group $rg --name "k8sWorker-$i" --template-file "template-workers.json" --parameters \
		moduleName=$module \
		subnetId=$AZURE_APP_VM_SUBNET_ID \
		vmAVSetId=$AZURE_K8S_WORKER_VM_AV_SET_ID \
		vmName=$vmName \
		vmPublicKey="$vmPublicKey" \
		vmSize=$vmSize \
		vmUser=$vmUser
		
done

