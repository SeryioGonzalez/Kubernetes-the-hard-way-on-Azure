#!/bin/bash

source config.sh

KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g $rg -n $aksMasterLbPublicIpName --query ipAddress -o tsv)

echo "CREATING CERT FOR KUBE API"
cat > $caFolder/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
	  "C": "ES",
	  "L": "Madrid",
	  "O": "Kubernetes",
	  "OU": "Kubernetes The Hard Way",
	  "ST": "Madrid"
	}
  ]
}
EOF

for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, privateIp:ipConfigurations[0].privateIpAddress}" -o tsv | sed 's/\t/_/; s/-nic//')
do
	vmName=$(echo $nicData | cut -d_ -f1)
	nicIp=$(echo $nicData  | cut -d_ -f2)
	nicId=$(echo $vmName   | cut -d- -f4)
	
	if [ $nicId -eq 0 ]
	then
		export MASTER_0_IP=$nicIp
	elif [ $nicId -eq 1 ]
	then
		export MASTER_1_IP=$nicIp
	elif [ $nicId -eq 2 ]
	then
		export MASTER_2_IP=$nicIp
	fi
done

cfssl gencert \
	-ca=$caFolder/ca.pem \
	-ca-key=$caFolder/ca-key.pem \
	-config=$caFolder/ca-config.json \
	-hostname=10.32.0.1,$MASTER_0_IP,$MASTER_1_IP,$MASTER_2_IP,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
	-profile=kubernetes \
	$caFolder/kubernetes-csr.json | cfssljson -bare kubernetes

mv kubernetes-key.pem $caFolder/kubernetes-key.pem
mv kubernetes.csr     $caFolder/kubernetes.csr
mv kubernetes.pem     $caFolder/kubernetes.pem

