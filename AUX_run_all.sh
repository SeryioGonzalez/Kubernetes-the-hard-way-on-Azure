
echo "Login to Azure"
set -e

./0_login.sh
./1.1_create_rg.sh
./1.2_create_vnet.sh

echo "CREATING MASTER VMs"
./2.1_create_aks_master_vms.sh

echo "CREATING WORKER VMs"
./3.1_create_aks_workers_vms.sh
echo "CREATING MASTER LB"
./2.2_create_aks_master_lb.sh

echo "CREATING CA AND CERTS"
./4.01_create_ca.sh
./4.02_create_cert_admin.sh
./4.03_create_cert_workers.sh
./4.04_create_cert_controller_manager.sh
./4.05_create_cert_proxy.sh
./4.06_create_cert_scheduler.sh
./4.07_create_cert_api.sh
./4.08_create_cert_service.sh

echo "PUSHING CONFIG TO NODES"
./4.09_copy_certs_workers.sh
./4.10_copy_certs_masters.sh
./4.11_create_aks_config.sh
./4.12_copy_aks_config.sh
./4.13_create_and_copy_aks_master_encryption.sh

echo "INSTALLING MASTER"
./5.1_create_aks_master_etcd.sh
./5.2_create_aks_master_control.sh
echo "INSTALLING WORKERS"
./6.1_install_aks_workers.sh
echo "CREATING KUBECONFIG"
./7.1_generate_kubectl_config.sh
echo "INSTALLING VNET ROUTES"
./8.1_generate_aks_worker_routes.sh

echo "WAITING FOR CLUSTER TO START"
sleep 100
./9.1_aks_dns_addon.sh

echo "SMOKE TEST INSTALLATION"
./9.2_check_pod.sh
