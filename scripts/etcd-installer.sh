wget -q  --https-only "https://github.com/etcd-io/etcd/releases/download/v3.5.5/etcd-v3.5.5-linux-amd64.tar.gz"

tar -xf etcd-v3.5.5-linux-amd64.tar.gz > /dev/null
sudo cp etcd-v3.5.5-linux-amd64/etcd* /usr/local/bin/

sudo mkdir -p /etc/etcd /var/lib/etcd
sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/

