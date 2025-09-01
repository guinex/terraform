#!/bin/bash
set -e

echo "⚠️ This will DESTROY Postgres (Helm release + Kubernetes objects + DATA on NFS)."
read -p "Proceed with FULL teardown? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Aborted."
  exit 1
fi

# Step 1: Uninstall Helm release
echo "🔻 Uninstalling Postgres Helm release..."
helm uninstall postgres -n database || true

# Step 2: Delete all Postgres-related Kubernetes resources
echo "🗑️ Deleting Postgres Kubernetes resources..."
kubectl delete all -n database -l app.kubernetes.io/name=postgresql --ignore-not-found
kubectl delete pvc -n database -l app.kubernetes.io/name=postgresql --ignore-not-found
kubectl delete pv postgres-nfs-pv --ignore-not-found
kubectl delete sc postgres-nfs-storage --ignore-not-found
kubectl delete ns database --ignore-not-found

# Step 3: Wipe NFS data folder
echo "💣 Removing ALL data from NFS mount (/mnt/nfs/postgres-data)..."
sudo rm -rf /mnt/nfs/postgres-data/*

# Step 4: Cleanup Terraform state
echo "🧹 Cleaning Terraform state..."
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl crash.log || true

echo "✅ Full Postgres teardown complete. All data and configs removed."
