#!/bin/bash

source config.sh

echo "CREATING K8S DNS CLUSTER ADD-ON"
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml