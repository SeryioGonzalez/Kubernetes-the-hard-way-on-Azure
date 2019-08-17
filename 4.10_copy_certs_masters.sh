#!/bin/bash

source config.sh

echo "COPYING CERTS TO MASTERS"
MASTER_PUBLIC_IP=$(az network public-ip show -g $rg -n $aksMasterLbPublicIpName --query ipAddress -o tsv)
for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, ipConfiguration:ipConfigurations[0].name}" -o tsv | sed 's/\t/_/')
do
	nicName=$(echo $nicData    | cut -d_ -f1)
	nicId=$(echo $nicName      | cut -d- -f4)
	
	echo "COPYING CERTS TO MASTER $nicId"
	
	scp -o StrictHostKeyChecking=no -P $aksMasterLbNATPortPrefix$nicId \
		$caFolder/ca.pem $caFolder/ca-key.pem \
		$caFolder/kubernetes-key.pem $caFolder/kubernetes.pem \
		$caFolder/service-account-key.pem $caFolder/service-account.pem $vmUser@${MASTER_PUBLIC_IP}:~/

done
