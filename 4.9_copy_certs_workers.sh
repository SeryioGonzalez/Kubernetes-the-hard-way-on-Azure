#!/bin/bash

source config.sh

echo "COPYING CERTS TO WORKERS"
for worker in $(az vm list -g $rg --query "[?tags.module == 'k8sworkers'].name" -o tsv)
do	
	echo "COPYING CERTS TO WORKER $worker"
	EXTERNAL_IP=$(az vm list-ip-addresses --query "[?virtualMachine.name == '$worker'].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)
	
	scp -o StrictHostKeyChecking=no $caFolder/${worker}*pem $caFolder/ca.pem $vmUser@${EXTERNAL_IP}:~/
	
done
