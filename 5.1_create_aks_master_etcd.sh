#!/bin/bash

source config.sh

echo "CREATING ETCD CONFIG WITH INFO FROM ALL MASTERS"
cp $etcdScriptTemplate $etcdScript
for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, privateIp:ipConfigurations[0].privateIpAddress}" -o tsv | sed 's/\t/_/; s/-nic//')
do
	vmName=$(echo $nicData | cut -d_ -f1)
	nicIp=$(echo $nicData  | cut -d_ -f2)
	nicId=$(echo $vmName   | cut -d- -f4)
	
	if [ $nicId -eq 0 ]
	then
		sed -i "s/__MASTER_0_IP__/$nicIp/g; s/__MASTER_0_NAME__/$vmName/g" $etcdScript
	elif [ $nicId -eq 1 ]
	then
		sed -i "s/__MASTER_1_IP__/$nicIp/g; s/__MASTER_1_NAME__/$vmName/g" $etcdScript
	elif [ $nicId -eq 2 ]
	then
		sed -i "s/__MASTER_2_IP__/$nicIp/g; s/__MASTER_2_NAME__/$vmName/g" $etcdScript
	fi
done

echo "CREATING MASTER SPECIFIC ETCD CONFIG FILES"
for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, privateIp:ipConfigurations[0].privateIpAddress}" -o tsv | sed 's/\t/_/; s/-nic//')
do
	vmName=$(echo $nicData | cut -d_ -f1)
	nicIp=$(echo $nicData  | cut -d_ -f2)
	
	masterEtcdScript=$(echo $etcdScriptTemplate | sed "s/template/$vmName/")
	cp $etcdScript $masterEtcdScript
	
	sed -i "s/__INTERNAL_IP__/$nicIp/g" $masterEtcdScript
	sed -i "s/__HOSTNAME__/$vmName/g"   $masterEtcdScript

done

rm $etcdScript

echo "COPYING ETCD CONFIG TO MASTERS"
MASTER_PUBLIC_IP=$(az network public-ip show -g $rg -n $aksMasterLbPublicIpName --query ipAddress -o tsv)
for vmName in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].name" -o tsv | sed 's/-nic//')
do
	nicId=$(echo $vmName   | cut -d- -f4)
	masterEtcdScript=$(echo $etcdScriptTemplate | sed "s/template/$vmName/")
	
	echo "COPYING ETCD IN MASTER $nicId"
	#Copy etcd installer
	scp -o StrictHostKeyChecking=no -P $aksMasterLbNATPortPrefix$nicId \
		$etcdInstallScript $vmUser@${MASTER_PUBLIC_IP}:~/
		
	#Copy etcd service	
	scp -o StrictHostKeyChecking=no -P $aksMasterLbNATPortPrefix$nicId \
		$masterEtcdScript $vmUser@${MASTER_PUBLIC_IP}:~/$etcdScriptName
	
	#Download and run etcd installers
	ssh -p $aksMasterLbNATPortPrefix$nicId $vmUser@${MASTER_PUBLIC_IP} "chmod 777 /home/$vmUser/$etcdInstallScriptName; /home/$vmUser/$etcdInstallScriptName"
		
	#Copy etcd service descriptor and start it
	ssh -p $aksMasterLbNATPortPrefix$nicId $vmUser@${MASTER_PUBLIC_IP} "sudo mv /home/$vmUser/$etcdScriptName /etc/systemd/system/etcd.service; sudo systemctl daemon-reload; sudo systemctl enable etcd; sudo systemctl start etcd"
	echo "INSTALLED ETCD IN MASTER $nicId"
done
