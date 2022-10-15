sudo mkdir -p /etc/kubernetes/config

sudo systemctl stop kube-apiserver kube-controller-manager kube-scheduler || echo "Master services were not running"

cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

wget -q --https-only --timestamping \
  "https://dl.k8s.io/v1.25.3/kubernetes-server-linux-amd64.tar.gz"

tar -xf kubernetes-server-linux-amd64.tar.gz 

chmod +x kubernetes/server/bin/kube-apiserver \
         kubernetes/server/bin/kube-controller-manager \
         kubernetes/server/bin/kube-scheduler \
         kubernetes/server/bin/kubectl

sudo cp kubernetes/server/bin/kube-apiserver kubernetes/server/bin/kube-controller-manager kubernetes/server/bin/kube-scheduler kubernetes/server/bin/kubectl /usr/local/bin/

sudo mkdir -p /var/lib/kubernetes/

sudo cp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/
	
sudo cp kube-controller-manager.kubeconfig /var/lib/kubernetes/

sudo cp kube-scheduler.kubeconfig /var/lib/kubernetes/

sudo cp *service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler


sudo apt-get update -y > /dev/null
sudo apt-get install -y nginx > /dev/null

cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

sudo mv kubernetes.default.svc.cluster.local /etc/nginx/sites-available/kubernetes.default.svc.cluster.local
sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/

sudo systemctl restart nginx
sudo systemctl enable nginx
