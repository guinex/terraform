#!/bin/bash
set -e

echo "⚠️ This will REMOVE Postgres Helm release + Kubernetes resources BUT KEEP data in /mnt/nfs/postgres-data."
read -p "Proceed with UPGRADE-SAFE teardown? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Aborted."
  exit 1
fi

# Step 1: Uninstall Helm release
echo "🔻 Uninstalling Postgres Helm release..."
helm uninstall postgres -n database || true

# Step 2: Delete Kubernetes resources (StatefulSet, PVCs, Services)
echo "🗑️ Deleting Postgres Kubernetes resources (keeping PV + data)..."
kubectl delete statefulset -n database -l app.kubernetes.io/name=postgresql --ignore-not-found
kubectl delete pvc -n database -l app.kubernetes.io/name=postgresql --ignore-not-found
kubectl delete svc -n database -l app.kubernetes.io/name=postgresql --ignore-not-found

# Step 3: Skip PV + StorageClass (to retain NFS data)
echo "⚠️ Keeping PV + StorageClass intact. Data is still in /mnt/nfs/postgres-data."

# Step 4: Cleanup Terraform state
echo "🧹 Cleaning Terraform state..."
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl crash.log || true

echo "✅ Upgrade-safe Postgres teardown complete. Data is preserved in /mnt/nfs/postgres-data."
