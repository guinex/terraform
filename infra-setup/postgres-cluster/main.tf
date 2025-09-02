provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Install K3s
resource "null_resource" "install_k3s" {
  provisioner "local-exec" {
    command = "bash ./install_k3s.sh"
  }
}

# Set Kubeconfig
resource "null_resource" "set_kubeconfig" {
  provisioner "local-exec" {
    command = "bash ./set_kubeconfig.sh"
  }
  depends_on = [null_resource.install_k3s]
}

# Persistent Volume using NFS
resource "kubernetes_persistent_volume" "postgres_pv" {
  metadata {
    name = "postgres-nfs-pv"
  }
  spec {
    capacity {
      storage = "10Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain" # Keeps data safe during Helm uninstall
    storage_class_name = "postgres-nfs-storage"
    persistent_volume_source {
      nfs {
        path   = "/mnt/nfs/postgres-data" # Your NFS mount point
        server = "YOUR_NFS_SERVER_IP"     # Replace with actual NFS server IP
        read_only = false
      }
    }
  }
}

# Storage Class for NFS
resource "kubernetes_storage_class" "postgres_sc" {
  metadata {
    name = "postgres-nfs-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
}

# Helm release for PostgreSQL
resource "helm_release" "postgres" {
  name             = "postgres"
  namespace        = "database"
  create_namespace = true
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql"
  version          = "13.1.2"

  set {
    name  = "auth.username"
    value = var.postgres_user
  }

  set {
    name  = "auth.password"
    value = var.postgres_password
  }

  set {
    name  = "auth.database"
    value = var.postgres_db
  }

  set {
    name  = "primary.service.type"
    value = "NodePort"
  }

  set {
    name  = "primary.service.nodePorts.postgresql"
    value = "31432"
  }

  # Enable persistence for PostgreSQL
  set {
    name  = "primary.persistence.enabled"
    value = "true"
  }

  set {
    name  = "primary.persistence.storageClass"
    value = kubernetes_storage_class.postgres_sc.metadata[0].name
  }

  set {
    name  = "primary.persistence.existingClaim"
    value = "postgres-pvc"
  }
}

# Persistent Volume Claim to bind PV to Postgres Helm chart
resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = "database"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests {
        storage = "10Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.postgres_sc.metadata[0].name
    volume_name        = kubernetes_persistent_volume.postgres_pv.metadata[0].name
  }
}