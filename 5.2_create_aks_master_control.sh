#!/bin/bash

source config.sh

echo "CREATING GENERIC MASTER API CONFIG"
cp $masterApiScriptTemplate $masterApiScript
for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, privateIp:ipConfigurations[0].privateIpAddress}" -o tsv | sed 's/\t/_/; s/-nic//')
do
	vmName=$(echo $nicData | cut -d_ -f1)
	nicIp=$(echo $nicData  | cut -d_ -f2)
	nicId=$(echo $vmName   | cut -d- -f4)
	
	if [ $nicId -eq 0 ]
	then
		sed -i "s/__MASTER_0_IP__/$nicIp/g; s/__MASTER_0_NAME__/$vmName/g" $masterApiScript
	elif [ $nicId -eq 1 ]
	then
		sed -i "s/__MASTER_1_IP__/$nicIp/g; s/__MASTER_1_NAME__/$vmName/g" $masterApiScript
	elif [ $nicId -eq 2 ]
	then
		sed -i "s/__MASTER_2_IP__/$nicIp/g; s/__MASTER_2_NAME__/$vmName/g" $masterApiScript
	fi
done

echo "CREATING SPECIFIC MASTER API CONFIG"
for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, privateIp:ipConfigurations[0].privateIpAddress}" -o tsv | sed 's/\t/_/; s/-nic//')
do
	vmName=$(echo $nicData | cut -d_ -f1)
	nicIp=$(echo $nicData  | cut -d_ -f2)
	thisMasterApiScript=$(echo $masterApiScriptTemplate | sed "s/template/$vmName/")
	cp $masterApiScript $thisMasterApiScript
	
	sed -i "s/__INTERNAL_IP__/$nicIp/g" $thisMasterApiScript
	sed -i "s/__HOSTNAME__/$vmName/g"   $thisMasterApiScript

done
rm $masterApiScript

echo "CREATING MASTER CONTROLLER MANAGER CONFIG"
cp $masterControllerManagerScriptTemplate $masterControllerManagerScript
sed -i "s~__CLUSTER_SUBNET_CIDR__~$podsCidr~" $masterControllerManagerScript

echo "INSTALLING MASTER SERVICES"
MASTER_PUBLIC_IP=$(az network public-ip show -g $rg -n $aksMasterLbPublicIpName --query ipAddress -o tsv)
for vmName in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].name" -o tsv | sed 's/-nic//')
do
	nicId=$(echo $vmName   | cut -d- -f4)
	thisMasterApiScript=$(echo $masterApiScriptTemplate | sed "s/template/$vmName/")
	
	echo "INSTALLING MASTER SERVICES IN MASTER $nicId "
	#Copy Master API installer
	
	scp -o StrictHostKeyChecking=no -P $aksMasterLbNATPortPrefix$nicId \
		$masterSchedulerServiceFile $masterControllerManagerScript $masterServicesInstallScript $vmUser@${MASTER_PUBLIC_IP}:~/
	
	scp -o StrictHostKeyChecking=no -P $aksMasterLbNATPortPrefix$nicId \
		$thisMasterApiScript $vmUser@${MASTER_PUBLIC_IP}:~/$masterApiScriptName
		
	#Download Master API binaries
	ssh -p $aksMasterLbNATPortPrefix$nicId $vmUser@${MASTER_PUBLIC_IP} "chmod 777 /home/$vmUser/$masterServicesInstallScriptName; /home/$vmUser/$masterServicesInstallScriptName"
	
done

echo "APPLYING RBAC ROLE"
scp -o StrictHostKeyChecking=no -P $aksMasterLbNATPortPrefix"0" \
		$masterRBACConfigFile $masterRBACConfigRoleAssignmentFile $vmUser@${MASTER_PUBLIC_IP}:~/
ssh -p $aksMasterLbNATPortPrefix"0" $vmUser@${MASTER_PUBLIC_IP} "kubectl apply --kubeconfig admin.kubeconfig -f $masterRBACConfigFileName"
ssh -p $aksMasterLbNATPortPrefix"0" $vmUser@${MASTER_PUBLIC_IP} "kubectl apply --kubeconfig admin.kubeconfig -f $masterRBACConfigRoleAssignmentFileName"
	
	