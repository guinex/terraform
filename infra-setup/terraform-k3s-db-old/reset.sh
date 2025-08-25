#!/bin/bash

set -e

echo "⚠️  This will destroy all Terraform-managed infrastructure and optionally remove Helm/K3s/kubectl."
read -p "Are you sure you want to proceed? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
  echo "❌ Reset aborted."
  exit 1
fi

# Step 1a: Remove docker registry
echo "🧹 Stopping and removing local Docker registry..."
if docker inspect registry >/dev/null 2>&1; then
  docker rm -f registry
fi

# Step 1b: Remove all images from local registry
echo "🧹 Removing all images from local registry..."
docker images --format "{{.Repository}}:{{.Tag}}" | grep "^localhost:5000/" || true | xargs -r docker rmi -f

sudo rm -f /etc/rancher/k3s/registries.yaml || true
sudo systemctl restart k3s

# Step 2a: Terraform destroy
echo "🧨 Running terraform destroy..."
terraform destroy

# Step 2b: unset KUBEVIRT_KUBECONFIG
echo "Unsetting KUBEVIRT_KUBECONFIG environment variable..."
unset KUBEVIRT_KUBECONFIG
echo "KUBEVIRT_KUBECONFIG has been unset."

# Step 3: Cleanup stray Helm releases (optional safety net)
echo "🧹 Checking for remaining Helm releases..."
helm list -A -q | while read release; do
  ns=$(helm list -A | grep "$release" | awk '{print $2}')
  echo "🔻 Deleting Helm release: $release in namespace: $ns"
  helm uninstall "$release" -n "$ns" || true
done

# Step 4: Delete ArgoCD namespace if exists
if kubectl get ns argocd &>/dev/null; then
  echo "🗑️ Deleting Argo CD namespace and resources..."
  kubectl delete ns argocd
fi

# Step 5: Remove ArgoCD admin password file
if [ -f "./argocd-admin-password.txt" ]; then
  echo "🗑️ Removing Argo CD admin password file..."
  rm -f ./argocd-admin-password.txt
fi

# Step 6: Remove Terraform working directory
echo "🧹 Cleaning up Terraform local state..."
rm -rf .terraform
rm -f terraform.tfstate
rm -f terraform.tfstate.backup
rm -f .terraform.lock.hcl
rm -f crash.log

# Step 7: (Optional) Uninstall K3s - Uncomment if you want full cluster wipe
echo "🗑️  Uninstalling K3s..."
/usr/local/bin/k3s-uninstall.sh || true

# Step 8: (Optional) Remove kubectl - Uncomment if desired
echo "🗑️  Removing kubectl binary..."
sudo rm -f /usr/local/bin/kubectl

# Step 9: Clear local kube config
echo "🧽 Cleaning kube config"
rm -rf ~/.kube

echo "✅ Reset complete. Cluster Helm state, docker registry and some config files cleaned."
