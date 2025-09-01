#!/bin/bash
set -e

echo "🚀 Starting local Docker registry..."

# Run registry if not running
docker ps | grep registry || docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Configure K3s to trust registry.local instead of localhost
echo "🛠️ Configuring K3s to trust registry.local..."
sudo mkdir -p /etc/rancher/k3s
cat <<EOF | sudo tee /etc/rancher/k3s/registries.yaml
mirrors:
  "registry.local:5000":
    endpoint:
      - "http://registry.local:5000"
EOF

# Restart K3s
echo "🔁 Restarting K3s..."
sudo systemctl restart k3s
echo " Check Registry via: docker ps | grep registry"
echo "✅ Local registry setup complete."
