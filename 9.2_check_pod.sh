#!/bin/bash

source config.sh

echo "TESTING POD"
for ipData in $(az network public-ip list -g $rg --query "[?tags.module == 'k8sworkers'].{ipAddress:ipAddress, name:name}" -o tsv | sed 's/-public-ip//; s/\t/_/')
do
	
	nicIp=$(echo  $ipData | cut -d_ -f1)
	vmName=$(echo $ipData | cut -d_ -f2)
	vmId=$(echo $vmName | cut -d- -f4)
	set -x
	ssh -o StrictHostKeyChecking=no $vmUser@${nicIp} \
		"curl --head http://10.1.0.3"
done
