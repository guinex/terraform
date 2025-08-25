# terraform {
#   required_providers {
#     helm = {
#       source = "hashicorp/helm"
#     }
#   }
# }

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "null_resource" "install_helm" {
  provisioner "local-exec" {
    command = "bash ./install_helm.sh"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}


resource "null_resource" "install_kubectl" {
  provisioner "local-exec" {
    command = "bash ./install_kubectl.sh"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "install_k3s" {
  provisioner "local-exec" {
    command = "bash ./install_k3s.sh"
  }

  depends_on = [
    null_resource.install_kubectl,
    null_resource.install_helm
  ]

  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "set_kubeconfig" {
  provisioner "local-exec" {
    command = "bash ./set_kubeconfig.sh"
  }
  depends_on = [null_resource.install_k3s] # Ensuring K3s is installed before setting kubeconfig
}

resource "null_resource" "install_registry" {
  provisioner "local-exec" {
    command = "bash ./install_registry.sh"
  }

  depends_on = [null_resource.install_k3s]
}

resource "helm_release" "postgres" {
  name       = "postgres"
  namespace  = "database"
  create_namespace = true
  depends_on = [null_resource.install_k3s]
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version = "13.1.2"
  
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

  # Pick a fixed NodePort so you always know where to connect
  set {
    name  = "primary.service.nodePorts.postgresql"
    value = "31432"
  }

  set {
    name  = "primary.persistence.enabled"
    value = "true"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.2.5" # Use latest stable or specific if needed

  values = [
    <<EOF
server:
  service:
    type: NodePort
    nodePortHttp: 30080
    nodePortHttps: 30443
EOF
  ]

  depends_on = [null_resource.set_kubeconfig]
}

resource "null_resource" "argocd_admin_password" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<EOT
      echo "🔐 Fetching Argo CD admin password..."
      kubectl get secret argocd-initial-admin-secret -n argocd \
        -o jsonpath="{.data.password}" | base64 -d > ./argocd-admin-password.txt
      echo "✅ Argo CD admin password written to ./argocd-admin-password.txt"
EOT
  }
}