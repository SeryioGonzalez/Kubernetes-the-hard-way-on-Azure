#!/bin/bash

subscription_id=$AZURE_SUBSCRIPTION_ID_POC

environment=sergiok8s
region=westeurope

rg=$environment"RG"

vnetName=$environment"vnet"
subnetName=$environment"subnet"
vnetPrefix="10.0.0.0/16"
subnetPrefix="10.0.0.0/24"
podsCidr="10.1.0.0/16"

vmSize="Standard_D4s_v3"
vmUser="sergio"

vm_public_key=$PUBLIC_KEY_FILE

avSetAksMastersName=$environment"MastersAvSet"
avSetAksWorkersName=$environment"WorkersAvSet"
k8s_cluster_name=$environment"-cluster"
aksMasterPrefix=$environment"-k8s-master-"
aksWorkerPrefix=$environment"-k8s-worker-"
aksWorkerCount=3
aksMasterCount=3

aksMasterLbName=$environment"-k8s-master-lb"
aksMasterLbPublicIpName=$environment"-k8s-master-public-ip"
aksMasterLbBackEndPoolName=$environment"-k8s-master-lb-bepool"
aksMasterLbProbeName=$environment"-k8s-master-lb-probe"
aksMasterLbRuleName=$environment"-k8s-master-lb-rule"
aksMasterLbNATPortPrefix="2220"

aksWorkerRTName=$environment"-k8s-workers-rt"

caFolder="ca"
configFolder="config"
scriptFolder="scripts"

etcdScriptTemplate="$scriptFolder/etcd.service.template"
etcdScriptName="etcd.service"
etcdScript="$scriptFolder/$etcdScriptName"
etcdInstallScriptName="etcd-installer.sh"
etcdInstallScript="$scriptFolder/$etcdInstallScriptName"

masterServicesInstallScriptName="master-installer.sh"
masterServicesInstallScript="$scriptFolder/$masterServicesInstallScriptName"

masterApiScriptTemplate="$scriptFolder/kube-apiserver.service.template"
masterApiScriptName="kube-apiserver.service"
masterApiScript="$scriptFolder/$masterApiScriptName"

masterControllerManagerScriptTemplate="$scriptFolder/kube-controller-manager.service.template"
masterControllerManagerScriptName="kube-controller-manager.service"
masterControllerManagerScript="$scriptFolder/$masterControllerManagerScriptName"

masterSchedulerServiceFileName="kube-scheduler.service"
masterSchedulerServiceFile="$scriptFolder/$masterSchedulerServiceFileName"

masterRBACConfigFileName="kube-apiserver-to-kubelet.yaml"
masterRBACConfigFile="$scriptFolder/$masterRBACConfigFileName"

masterRBACConfigRoleAssignmentFileName="kube-apiserver-to-kubelet-role-assignment.yaml"
masterRBACConfigRoleAssignmentFile="$scriptFolder/$masterRBACConfigRoleAssignmentFileName"

workerInstallScriptName="worker-installer.sh"
workerInstallScript="$scriptFolder/$workerInstallScriptName"

set -e

az account set -s $subscription_id
