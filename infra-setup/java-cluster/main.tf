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
