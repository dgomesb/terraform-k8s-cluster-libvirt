#!/usr/bin/env bash

sleep 3

if ! command -v kubeadm &> /dev/null; then
  echo "Error: 'kubeadm' is not installed"
  exit 1
fi

%{ if pod_cidr != "" }
sudo kubeadm init --pod-network-cidr=${pod_cidr} --apiserver-advertise-address=${main_cp_ip} &> /shared/kubeadm-init.out
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
chmod 666 /shared/kubeadm-init.out

## https://github.com/weaveworks/weave/blob/master/site/kubernetes/kube-addon.md#-installation
#kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

# https://github.com/flannel-io/flannel?tab=readme-ov-file#deploying-flannel-manually
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

## MetalLB is a load-balancer
# https://metallb.io/installation/#installation-by-manifest
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml

%{ else }
FILE="/shared/kubeadm-init.out"
TOKEN=""
HASH=""
while [[ -z "$TOKEN" || -z "$HASH" ]]; do
  TOKEN=$(sed -n 's/.*--token \([^ ]*\).*/\1/p' "$FILE" 2>/dev/null)
  HASH=$(sed -n 's/.*--discovery-token-ca-cert-hash \([^ ]*\).*/\1/p' "$FILE" 2>/dev/null)
  if [[ -z "$TOKEN" || -z "$HASH" ]]; then
    sleep 5
  fi
done

sudo kubeadm join ${main_cp_ip}:6443 \
  --token $TOKEN \
  --discovery-token-ca-cert-hash $HASH \
  --cri-socket unix:///var/run/containerd/containerd.sock \
  &> /shared/kubeadm-join-$HOSTNAME.out
chmod 666 /shared/kubeadm-join-$HOSTNAME.out

%{ endif }
## comment out to avoid future execution
crontab -l | sed '/myKubeadm/s/^/# /' | crontab - 2>/dev/null

exit 0
