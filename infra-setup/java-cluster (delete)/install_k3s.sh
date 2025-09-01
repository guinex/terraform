#!/bin/bash
set -e


if ! command -v k3s &>/dev/null; then
	echo "Installing K3s..."
	curl -sfL https://get.k3s.io | sh -
else
  echo "K3s already installed"
fi

mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

echo "K3s installed. Checking status..."
sudo k3s kubectl get nodes
