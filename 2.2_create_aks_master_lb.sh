#!/bin/bash

source config.sh

module="k8smasters"

echo "Creating API lb for master VMs"
az network public-ip create -g $rg -n $aksMasterLbPublicIpName --allocation-method Static
az network lb create -g $rg -n $aksMasterLbName --backend-pool-name $aksMasterLbBackEndPoolName --public-ip-address $aksMasterLbPublicIpName

echo "Adding Master VM NICs to lb pool"
for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, ipConfiguration:ipConfigurations[0].name}" -o tsv | sed 's/\t/_/')
do
	nicName=$(echo $nicData    | cut -d_ -f1)
	ipConfName=$(echo $nicData | cut -d_ -f2)
	nicId=$(echo $nicName      | cut -d- -f4)
	
	#Add VM NIC to LB address pool
	az network nic ip-config address-pool add -g $rg \
		--nic-name $nicName -n $ipConfName \
		--lb-name $aksMasterLbName --address-pool $aksMasterLbBackEndPoolName
	
	#Create a NAT rule
	az network lb inbound-nat-rule create -g $rg -n "natRule-$nicId" \
		--lb-name $aksMasterLbName --protocol Tcp \
        --frontend-port "$aksMasterLbNATPortPrefix$nicId" --backend-port 22 --frontend-ip-name LoadBalancerFrontEnd
	
	#Associate NAT Rule to NIC
	az network nic ip-config update -g $rg \
		--nic-name $nicName -n $ipConfName \
		--lb-name $aksMasterLbName --lb-inbound-nat-rules "natRule-$nicId"

done

echo "Adding lb probe"
az network lb probe create -g $rg --lb-name $aksMasterLbName -n $aksMasterLbProbeName --protocol Tcp --port 6443 --interval 5 --threshold 2

echo "Adding lb rule"
az network lb rule  create -g $rg --lb-name $aksMasterLbName -n $aksMasterLbRuleName  --protocol Tcp --frontend-port 6443 --backend-port 6443 --backend-pool-name $aksMasterLbBackEndPoolName --probe-name $aksMasterLbProbeName