provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "null_resource" "install_k3s" {
  provisioner "local-exec" {
    command = "bash ./install_k3s.sh"
  }
}

resource "null_resource" "set_kubeconfig" {
  provisioner "local-exec" {
    command = "bash ./set_kubeconfig.sh"
  }
  depends_on = [null_resource.install_k3s]
}

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

  set {
    name  = "primary.persistence.enabled"
    value = "true"
  }
}
