#!/bin/bash

source config.sh

az connectedk8s connect --name $k8s_cluster_name --resource-group $rg