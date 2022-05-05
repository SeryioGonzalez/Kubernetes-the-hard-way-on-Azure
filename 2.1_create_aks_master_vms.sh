#!/bin/bash

source config.sh

module="k8smasters"

echo "Creating av-set for master VMs"
az vm availability-set create -g $rg -n $avSetAksMastersName --tags module=$module -o none

export AZURE_K8S_MASTER_VM_AV_SET_ID=$(az vm availability-set show -g $rg -n $avSetAksMastersName --query id -o tsv)
export AZURE_APP_VM_SUBNET_ID=$(az network vnet subnet show -g $rg --vnet $vnetName --name $subnetName --query id -o tsv)

for i in $(seq 0 `expr $aksMasterCount - 1`)
do
	echo "Creating K8S Master $i"
	vmName=$aksMasterPrefix$i
	az deployment group create --no-wait --resource-group $rg --name "k8sMaster-$i" --template-file "template-masters.json" --parameters \
		moduleName=$module \
		subnetId=$AZURE_APP_VM_SUBNET_ID \
		vmAVSetId=$AZURE_K8S_MASTER_VM_AV_SET_ID \
		vmName=$vmName \
		vmPublicKey="$vmPublicKey" \
		vmSize=$vmSize \
		vmUser=$vmUser -o none
		
done

