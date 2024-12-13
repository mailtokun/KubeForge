resource "null_resource" "k8s_network" {
  depends_on = [null_resource.k8s_master]

  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = "root"
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
    ]
  }
}
