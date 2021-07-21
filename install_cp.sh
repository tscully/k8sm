#!/bin/sh

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm/

### setup terminal
apt-get install -y bash-completion binutils
echo 'colorscheme ron' >> ~/.vimrc
echo 'set tabstop=2' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc


### install k8s and docker
apt-get remove -y docker.io kubelet kubeadm kubectl kubernetes-cni
apt-get autoremove -y
apt-get install -y etcd-client vim build-essential

systemctl daemon-reload
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
KUBE_VERSION=1.21.2
apt-get update
apt-get install -y kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00 kubernetes-cni=0.8.7-00

### install containerd
sleep 3

apt-get install -y containerd

cat <<EOF > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml


systemctl restart containerd

#cat <<EOF > /etc/default/kubelet
#KUBELET_EXTRA_ARGS=--cgroup-driver=systemd
#EOF


sleep 3

systemctl enable kubelet && systemctl start kubelet


### init k8s
rm /root/.kube/config
kubeadm reset -f
kubeadm init --kubernetes-version=${KUBE_VERSION} --pod-network-cidr=10.64.0.0/16 --ignore-preflight-errors=NumCPU --skip-token-print 

mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config

kubectl apply -f https://github.com/vmware-tanzu/antrea/releases/download/v1.2.0/antrea.yml

echo
echo "### COMMAND TO ADD A WORKER NODE ###"
kubeadm token create --print-join-command --ttl 0
