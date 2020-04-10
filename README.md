# Kubernetes The Hard Way - Azure version

Inspired in [**Kubernetes The Hard Way**](https://github.com/kelseyhightower/kubernetes-the-hard-way) from the Kubernetes legend Kelsey Hightower.<br/>
The purpose of the original repo is building a Kubernetes cluster step by step using raw servers. As Kelsey indicates, this should never be used in production. It is a highly recommended exercise for those aspiring to master Kubernetes and a must-do for CKA prospects. <br/>
Kelsey uses VMs on GCP. I have done an equivalent for Azure. For production projects, check [Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/)

## Prerequisites
You need an Azure subscription and AZ CLI installed.<br/>
Update the variables ```vmUser``` and ```vmPublicKey``` with your desired values in ```config.sh```.