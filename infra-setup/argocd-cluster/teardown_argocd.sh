#!/bin/bash
set -e

echo "⚠️ This will destroy ArgoCD + Terraform-managed resources."
read -p "Proceed? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Aborted."
  exit 1
fi

# Step 1: Terraform destroy (ArgoCD only)
terraform destroy -auto-approve

# Step 2: Delete ArgoCD namespace if exists
if kubectl get ns argocd &>/dev/null; then
  echo "🗑️ Deleting Argo CD namespace..."
  kubectl delete ns argocd
fi

# Step 3: Remove ArgoCD admin password file
rm -f ./argocd-admin-password.txt || true

# Step 4: Cleanup Helm releases (safety net)
helm list -n argocd -q | while read release; do
  echo "🔻 Deleting Helm release: $release"
  helm uninstall "$release" -n argocd || true
done

# Step 5: Clean TF state
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl crash.log || true

echo "✅ ArgoCD teardown complete."