#!/bin/bash

source config.sh

echo "CREATING ADMIN CERTS"
cat > $caFolder/admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ES",
      "L": "Madrid",
      "O": "system:masters",
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
  $caFolder/admin-csr.json | cfssljson -bare admin

mv admin-key.pem $caFolder/admin-key.pem
mv admin.csr     $caFolder/admin.csr
mv admin.pem     $caFolder/admin.pem