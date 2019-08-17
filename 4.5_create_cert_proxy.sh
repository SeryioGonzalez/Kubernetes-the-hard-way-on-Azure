#!/bin/bash

source config.sh

echo "CREATING CERT FOR KUBE PROXY"
cat > $caFolder/kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ES",
      "L": "Madrid",
      "O": "system:node-proxier",
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
  $caFolder/kube-proxy-csr.json | cfssljson -bare kube-proxy


mv kube-proxy-key.pem $caFolder/kube-proxy-key.pem
mv kube-proxy.csr     $caFolder/kube-proxy.csr
mv kube-proxy.pem     $caFolder/kube-proxy.pem
