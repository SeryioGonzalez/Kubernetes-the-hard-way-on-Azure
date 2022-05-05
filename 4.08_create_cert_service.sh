#!/bin/bash

source config.sh

echo "CREATING CERT FOR KUBE SERVICE"
cat > $caFolder/service-account-csr.json <<EOF
{
  "CN": "service-accounts",
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

cfssl gencert \
  -ca=$caFolder/ca.pem \
  -ca-key=$caFolder/ca-key.pem \
  -config=$caFolder/ca-config.json \
  -profile=kubernetes \
  $caFolder/service-account-csr.json | cfssljson -bare service-account


mv service-account-key.pem $caFolder/service-account-key.pem
mv service-account.csr     $caFolder/service-account.csr
mv service-account.pem     $caFolder/service-account.pem
