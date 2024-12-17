resource "null_resource" "k8s_network" {
  depends_on = [null_resource.k8s_master]

  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl https://docs.projectcalico.org/manifests/calico.yaml -O",
      "sudo kubectl apply -f calico.yaml",
      "sudo kubectl get pods -n kube-system"
    ]
  }
}
