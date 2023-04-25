#!/bin/bash

source config.sh

echo "CREATING CERTS FOR WORKERS"

for worker in $(az vm list -g $rg --query "[?tags.module == 'k8sworkers'].name" -o tsv)
do	
	echo "CREATING CERTS FOR WORKER $worker"
	EXTERNAL_IP=$(az vm list-ip-addresses --query "[?virtualMachine.name == '$worker'].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)
	INTERNAL_IP=$(az vm list-ip-addresses --query "[?virtualMachine.name == '$worker'].virtualMachine.network.privateIpAddresses[0]" -o tsv)
	
	cat > $caFolder/${worker}-csr.json <<EOF
{
  "CN": "system:node:${worker}",
  "key": {
	"algo": "rsa",
	"size": 2048
  },
  "names": [
	{
	  "C": "ES",
	  "L": "Madrid",
	  "O": "system:nodes",
	  "OU": "Kubernetes The Hard Way",
	  "ST": "Madrid"
	}
  ]
}
EOF
	
	cfssl gencert \
		-ca=$caFolder/ca.pem \
		-ca-key=$caFolder/ca-key.pem \
		-config=$caFolder/ca-config.json \
		-hostname=${worker},${EXTERNAL_IP},${INTERNAL_IP} \
		-profile=kubernetes \
		$caFolder/${worker}-csr.json | cfssljson -bare ${worker}
	
	mv ${worker}-key.pem $caFolder/${worker}-key.pem
	mv ${worker}.csr     $caFolder/${worker}.csr
	mv ${worker}.pem     $caFolder/${worker}.pem
done
