#!/bin/bash
set -e

echo "⚠️ This will destroy Postgres (Helm release + Terraform state) on this VM."
read -p "Proceed? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Aborted."
  exit 1
fi

# Step 1: Terraform destroy (DB only)
echo "🧨 Running terraform destroy for Postgres..."
terraform destroy -auto-approve

# Step 2: Cleanup Helm releases (safety net)
helm list -n database -q | while read release; do
  echo "🔻 Deleting Helm release: $release"
  helm uninstall "$release" -n database || true
done

# Step 3: Cleanup Terraform state files
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl crash.log || true

echo "✅ Postgres teardown complete."
