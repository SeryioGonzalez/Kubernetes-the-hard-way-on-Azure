#!/bin/bash

source config.sh

echo "CREATING CERT FOR KUBE SCHEDULER"
cat > $caFolder/kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "ES",
      "L": "Madrid",
      "O": "system:kube-scheduler",
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
  $caFolder/kube-scheduler-csr.json | cfssljson -bare kube-scheduler


mv kube-scheduler-key.pem $caFolder/kube-scheduler-key.pem
mv kube-scheduler.csr     $caFolder/kube-scheduler.csr
mv kube-scheduler.pem     $caFolder/kube-scheduler.pem
