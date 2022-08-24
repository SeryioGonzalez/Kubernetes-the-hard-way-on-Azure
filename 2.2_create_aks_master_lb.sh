#!/bin/bash

source config.sh

module="k8smasters"

echo "Creating public IP for Master API LB"
az network public-ip create -g $rg -n $aksMasterLbPublicIpName --sku Basic --allocation-method Static -o none
echo "Creating lb for Master API LB"
az network lb create -g $rg -n $aksMasterLbName --backend-pool-name $aksMasterLbBackEndPoolName --public-ip-address $aksMasterLbPublicIpName -o none

echo "Adding Master VM NICs to lb pool"
for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, ipConfiguration:ipConfigurations[0].name}" -o tsv | sed 's/\t/_/')
do
	nicName=$(echo $nicData    | cut -d_ -f1)
	ipConfName=$(echo $nicData | cut -d_ -f2)
	nicId=$(echo $nicName      | cut -d- -f4)
	
	#Add VM NIC to LB address pool
	az network nic ip-config address-pool add -g $rg \
		--nic-name $nicName -n $ipConfName \
		--lb-name $aksMasterLbName --address-pool $aksMasterLbBackEndPoolName -o none
	
	#Create a NAT rule
	az network lb inbound-nat-rule create -g $rg -n "natRule-$nicId" \
		--lb-name $aksMasterLbName --protocol Tcp \
        --frontend-port "$aksMasterLbNATPortPrefix$nicId" --backend-port $ssh_vm_port --frontend-ip-name LoadBalancerFrontEnd -o none
	
	#Associate NAT Rule to NIC
	az network nic ip-config update -g $rg \
		--nic-name $nicName -n $ipConfName \
		--lb-name $aksMasterLbName --lb-inbound-nat-rules "natRule-$nicId" -o none

	echo "NIC $nicName configured"

done

echo "Adding lb probe"
az network lb probe create -g $rg --lb-name $aksMasterLbName -n $aksMasterLbProbeName --protocol Tcp --port 6443 --interval 5 --threshold 2 -o none

echo "Adding lb rule"
az network lb rule  create -g $rg --lb-name $aksMasterLbName -n $aksMasterLbRuleName  --protocol Tcp --frontend-port 6443 --backend-port 6443 --backend-pool-name $aksMasterLbBackEndPoolName --probe-name $aksMasterLbProbeName -o none