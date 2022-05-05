#!/bin/bash

source config.sh

echo "GENERATING ENCRYPTION KEY"
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > $configFolder/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

echo "COPYING ENCRYPTION CONFIG TO MASTERS"
MASTER_PUBLIC_IP=$(az network public-ip show -g $rg -n $aksMasterLbPublicIpName --query ipAddress -o tsv)
for nicData in $(az network nic list -g $rg --query "[?tags.module == 'k8smasters'].{name:name, ipConfiguration:ipConfigurations[0].name}" -o tsv | sed 's/\t/_/')
do
	nicName=$(echo $nicData    | cut -d_ -f1)
	nicId=$(echo $nicName      | cut -d- -f4)
	echo "COPYING ENCRYPTION CONFIG TO MASTER $nicId"
	scp -o StrictHostKeyChecking=no -P $aksMasterLbNATPortPrefix$nicId \
		$configFolder/encryption-config.yaml \
		$vmUser@${MASTER_PUBLIC_IP}:~/
	
done
