#!/bin/bash

source config.sh

echo "CREATING RT FOR WORKERS"

az network route-table create -g $rg -n $aksWorkerRTName  -o none
az network vnet subnet update -g $rg --vnet-name $vnetName --name $subnetName --route-table $aksWorkerRTName  -o none

ipCidrOctec1=$(echo $podsCidr | cut -d. -f1)
ipCidrOctec2=$(echo $podsCidr | cut -d. -f2)

echo "CREATING ROUTES FOR EACH WORKER"
for workerData in $(az network public-ip list --query "[?tags.module == 'k8sworkers'].[ipAddress, name]" -o tsv | sed 's/\t/_/')
do
	workerIpAddress=$(echo $workerData | cut -d_ -f1)
	workerIpName=$(echo $workerData    | cut -d_ -f2)
	workerName=$(echo $workerIpName | sed 's/-public-ip//')
	workerId=$(echo $workerName | cut -d- -f4)
	
	workerNicName=$workerName"-nic"
	workerPrivateIp=$(az network nic show -g $rg -n $workerNicName --query "ipConfigurations[0].privateIpAddress" -o tsv)
	
	podsCidr="$ipCidrOctec1.$ipCidrOctec2.$workerId.0/24"
	
	echo "CREATING ROUTE FOR WORKER $workerName"
	az network route-table route create -g $rg -n "to_$workerName" \
		--route-table-name $aksWorkerRTName --address-prefix $podsCidr \
		--next-hop-type VirtualAppliance \
		--next-hop-ip-address $workerPrivateIp -o none

done
