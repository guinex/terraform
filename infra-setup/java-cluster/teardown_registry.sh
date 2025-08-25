#!/bin/bash
set -e

echo "⚠️ This will destroy Registry + Terraform-managed resources on this VM."
read -p "Proceed? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Aborted."
  exit 1
fi

# Step 1: Stop/remove registry container
if docker inspect registry >/dev/null 2>&1; then
  echo "🧹 Stopping and removing local Docker registry..."
  docker rm -f registry
fi

# Step 2: Remove local registry images
echo "🧹 Removing images from local registry..."
docker images --format "{{.Repository}}:{{.Tag}}" | grep "^localhost:5000/" || true | xargs -r docker rmi -f

# Step 3: Reset K3s registry config
sudo rm -f /etc/rancher/k3s/registries.yaml || true
sudo systemctl restart k3s

# Step 4: Terraform destroy
echo "🧨 Running terraform destroy..."
terraform destroy -auto-approve

# Step 5: Cleanup Helm releases (safety net)
helm list -A -q | while read release; do
  ns=$(helm list -A | grep "$release" | awk '{print $2}')
  echo "🔻 Deleting Helm release: $release in namespace: $ns"
  helm uninstall "$release" -n "$ns" || true
done

# Step 6: Clean TF state
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl crash.log || true

echo "✅ Registry + App teardown complete."
