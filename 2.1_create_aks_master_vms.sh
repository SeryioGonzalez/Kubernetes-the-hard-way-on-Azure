#!/bin/bash

source config.sh

module="k8smasters"

echo "Creating av-set for master VMs"
az vm availability-set create -g $rg -n $avSetAksMastersName --tags module=$module -o none

echo "Creating nsg for master VMs"
nsg_name=$aksMasterPrefix"nsg"
az network nsg create -g $rg -n $nsg_name -o none

echo "Creating nsg rules for master VMs"
az network nsg rule create -g $rg --nsg-name $nsg_name -n ssh_alternative --priority 200 --source-address-prefixes '*' --destination-port-ranges $ssh_vm_port --access Allow --protocol Tcp --description "Allow ssh on port $ssh_vm_port" -o none
az network nsg rule create -g $rg --nsg-name $nsg_name -n etcd_control    --priority 201 --source-address-prefixes '*' --destination-port-ranges 6443 --access Allow --protocol Tcp --description "Allow etcd on port 6443" -o none


export AZURE_K8S_MASTER_VM_AV_SET_ID=$(az vm availability-set show -g $rg -n $avSetAksMastersName --query id -o tsv)
export AZURE_K8S_MASTER_VM_NSG_ID=$(az network nsg show -g $rg -n $nsg_name --query id -o tsv )
export AZURE_APP_VM_SUBNET_ID=$(az network vnet subnet show -g $rg --vnet $vnetName --name $subnetName --query id -o tsv)

#Creating Master VMs
for i in $(seq 0 `expr $aksMasterCount - 1`)
do
	echo "Creating K8S Master $i"
	vmName=$aksMasterPrefix$i
	az deployment group create --no-wait --resource-group $rg --name "k8sMaster-$i" --template-file "template-masters.json" --parameters \
		moduleName=$module \
		nsgId=$AZURE_K8S_MASTER_VM_NSG_ID \
		subnetId=$AZURE_APP_VM_SUBNET_ID \
		vmAVSetId=$AZURE_K8S_MASTER_VM_AV_SET_ID \
		vmName=$vmName \
		vmPublicKey="$vm_public_key" \
		vmSize=$vmSize \
		vmUser=$vmUser -o none
done

echo "Waiting for VMs to be created"
sleep 100
echo "Continuing process"

#Configuring master VMs
for i in $(seq 0 `expr $aksMasterCount - 1`)
do

	echo "Checking K8S Master $i Running"
	vmName=$aksMasterPrefix$i
	VM_STATUS=$(az vm show -d -g $rg -n $vmName --query "powerState" -o tsv | awk '{print $2}')

	if [ $VM_STATUS != "running" ]
	then
		echo "$vmName is not running. Starting"
		az vm start -g $rg -n $vmName -o none
	else
		echo "$vmName is running"
	fi

	echo "Configuring K8S Master $i"
	az vm run-command invoke -g $rg -n $vmName --command-id RunShellScript --scripts "sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config; systemctl restart sshd" --query "value[0].displayStatus"
	
done
