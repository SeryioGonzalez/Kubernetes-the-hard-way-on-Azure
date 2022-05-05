#!/bin/bash

source config.sh

echo "CREATING CERT FOR CONTROLLER MANAGER"
cat > $caFolder/kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ES",
      "L": "Madrid",
      "O": "system:kube-controller-manager",
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
  $caFolder/kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager


mv kube-controller-manager-key.pem $caFolder/kube-controller-manager-key.pem
mv kube-controller-manager.csr     $caFolder/kube-controller-manager.csr
mv kube-controller-manager.pem     $caFolder/kube-controller-manager.pem
