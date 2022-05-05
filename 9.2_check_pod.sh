#!/bin/bash

source config.sh

echo "Deploy sample nginx deployment"
kubectl apply -f https://k8s.io/examples/application/deployment.yaml

sleep 30

one_pod_ip=$(kubectl get pod -o jsonpath="{.items[0].status.podIP}")

echo "Testing pod connectivity from workers"
for ipData in $(az network public-ip list -g $rg --query "[?tags.module == 'k8sworkers'].{ipAddress:ipAddress, name:name}" -o tsv | sed 's/-public-ip//; s/\t/_/')
do
	
	nicIp=$(echo  $ipData | cut -d_ -f1)
	vmName=$(echo $ipData | cut -d_ -f2)
	vmId=$(echo $vmName | cut -d- -f4)

	response_code_from_pod=$(ssh -o StrictHostKeyChecking=no $vmUser@${nicIp} "curl -s --head -o /dev/null -w "%{http_code}" http://$one_pod_ip")

	echo "From $vmName response code to pod is $response_code_from_pod"
done
