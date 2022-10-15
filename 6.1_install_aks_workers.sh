#!/bin/bash

source config.sh

ipCidrOctec1=$(echo $podsCidr | cut -d. -f1)
ipCidrOctec2=$(echo $podsCidr | cut -d. -f2)
ipCidrOctec3=$(echo $podsCidr | cut -d. -f3)

echo "INSTALLING WORKERS"
for ipData in $(az network public-ip list -g $rg --query "[?tags.module == 'k8sworkers'].{ipAddress:ipAddress, name:name}" -o tsv | sed 's/-public-ip//; s/\t/_/')
do
	
	nicIp=$(echo  $ipData | cut -d_ -f1)
	vmName=$(echo $ipData | cut -d_ -f2)
	vmId=$(echo $vmName | cut -d- -f4)
	
	thisWorkerPodsCidr="$ipCidrOctec1.$ipCidrOctec2.$vmId.0/24"
	
	echo "INSTALLING WORKER $vmName"
	scp -P $ssh_vm_port -o StrictHostKeyChecking=no $workerInstallScript $vmUser@${nicIp}:~/
	ssh -p $ssh_vm_port -o StrictHostKeyChecking=no $vmUser@${nicIp} "chmod 777 /home/$vmUser/$workerInstallScriptName; /home/$vmUser/$workerInstallScriptName $thisWorkerPodsCidr $podsCidr"
	
done
