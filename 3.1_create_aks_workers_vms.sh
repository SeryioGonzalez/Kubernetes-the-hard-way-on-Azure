#!/bin/bash

source config.sh

module="k8sworkers"

aksLastWorkerIndex=$(expr $aksWorkerCount - 1)

echo "Creating av-set for worker VMs"
az vm availability-set create -g $rg -n $avSetAksWorkersName --tags module=$module  -o none

echo "Creating nsg for worker VMs"
nsg_name=$aksWorkerPrefix"nsg"
az network nsg create -g $rg -n $nsg_name -o none

echo "Creating nsg rule for worker VMs"
az network nsg rule create -g $rg --nsg-name $nsg_name -n ssh_alternative --priority 200 --source-address-prefixes '*' --destination-port-ranges $ssh_vm_port --access Allow --protocol Tcp --description "Allow ssh on ports $ssh_vm_port" -o none

export AZURE_K8S_WORKER_VM_AV_SET_ID=$(az vm availability-set show -g $rg -n $avSetAksWorkersName --query id -o tsv)
export AZURE_K8S_WORKER_VM_NSG_ID=$(az network nsg show -g $rg -n $nsg_name --query id -o tsv )
export AZURE_APP_VM_SUBNET_ID=$(az network vnet subnet show -g $rg --vnet $vnetName --name $subnetName --query id -o tsv)

for i in $(seq 0 $aksLastWorkerIndex)
do
	echo "Creating K8S Worker $i"
	vmName=$aksWorkerPrefix$i
	az deployment group create --no-wait --resource-group $rg --name "k8sWorker-$i" --template-file "template-workers.json" --parameters \
		moduleName=$module \
		nsgId=$AZURE_K8S_WORKER_VM_NSG_ID \
		subnetId=$AZURE_APP_VM_SUBNET_ID \
		vmAVSetId=$AZURE_K8S_WORKER_VM_AV_SET_ID \
		vmName=$vmName \
		vmPublicKey="$vm_public_key" \
		vmSize=$vmSize \
		vmUser=$vmUser  -o none
		
done

echo "Waiting for VMs to be created"
sleep 100
echo "Continuing process"

#Configuring worker VMs
for i in $(seq 0 `expr $aksWorkerCount - 1`)
do
	
	echo "Checking K8S Worker $i Running"
	vmName=$aksWorkerPrefix$i
	VM_STATUS=$(az vm show -d -g $rg -n $vmName --query "powerState" -o tsv | awk '{print $2}')

	if [ $VM_STATUS != "running" ]
	then
		echo "$vmName is not running. Starting"
		az vm start -g $rg -n $vmName -o none
	else
		echo "$vmName is running"
	fi

	echo "Configuring K8S Worker $i"
	az vm run-command invoke -g $rg -n $vmName --command-id RunShellScript --scripts "sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config; systemctl restart sshd" --query "value[0].displayStatus"
	
done
