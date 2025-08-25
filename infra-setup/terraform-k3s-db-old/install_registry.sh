#!/bin/bash
set -e

echo "🚀 Starting local Docker registry..."

# Step 1: Run local registry if not exists
docker inspect registry >/dev/null 2>&1 || \
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Step 2: Configure K3s to trust the registry
echo "🛠️ Configuring K3s to trust the registry..."
sudo mkdir -p /etc/rancher/k3s
cat <<EOF | sudo tee /etc/rancher/k3s/registries.yaml
mirrors:
  "localhost:5000":
    endpoint:
      - "http://localhost:5000"
EOF

# Step 3: Restart K3s
echo "🔁 Restarting K3s..."
sudo systemctl restart k3s

echo "✅ Local registry setup complete."