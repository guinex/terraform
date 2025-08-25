#!/bin/bash
set -e

echo "📦 Installing kubectl..."

VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt || echo "v1.33.3")
URL="https://dl.k8s.io/${VERSION}/bin/linux/amd64/kubectl"

echo "📥 Downloading kubectl version $VERSION..."
curl -LO "$URL"

chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "✅ kubectl installed at /usr/local/bin/kubectl"
kubectl version --client