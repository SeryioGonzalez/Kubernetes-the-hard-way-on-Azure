#!/bin/bash

source config.sh

echo "Creating RG $rg"
az group create --name $rg --location $region -o none