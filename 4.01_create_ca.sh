#!/bin/bash

source config.sh

mkdir -p $caFolder
find $caFolder -type f -exec rm {} \;

echo "CREATING CA"
cat > $caFolder/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > $caFolder/ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ES",
      "L": "Madrid",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Madrid"
    }
  ]
}
EOF

cfssl gencert -initca $caFolder/ca-csr.json | cfssljson -bare ca

mv ca-key.pem $caFolder/ca-key.pem
mv ca.csr     $caFolder/ca.csr
mv ca.pem     $caFolder/ca.pem