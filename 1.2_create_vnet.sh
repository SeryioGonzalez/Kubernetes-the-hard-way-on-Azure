#!/bin/bash

source config.sh

echo "Creating vnet"
az network vnet create -g $rg -n $vnetName \
	--address-prefixes $vnetPrefix \
	--subnet-name $subnetName --subnet-prefix $subnetPrefix -o none
