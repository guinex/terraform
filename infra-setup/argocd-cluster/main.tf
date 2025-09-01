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

# Local Registry Setup (shared hostname)
resource "null_resource" "install_registry" {
  provisioner "local-exec" {
    command = "bash ./install_registry.sh"
  }
  depends_on = [null_resource.install_k3s]
}


resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.2.5"

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
      sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -data.password}" | base64 -d > ./argocd-admin-password.txt
      echo "✅ Argo CD admin password written to ./argocd-admin-password.txt"
EOT
  }
}
