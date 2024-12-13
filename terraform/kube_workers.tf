resource "null_resource" "k8s_worker" {
  depends_on = [null_resource.k8s_network]  # 确保Master节点和network插件创建完成后执行   
  count = 4  # 4个Worker节点

  connection {
    type        = "ssh"
    host        = var.worker_ips[count.index]
    user        = "root"
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "TOKEN=${var.kubeadm_token}",  # 从 Terraform 输出变量传递 token
      "HASH=${var.ca_cert_hash}",    # 从 Terraform 输出变量传递 hash
      "kubeadm join ${var.master_ip}:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$HASH --cri-socket /var/run/containerd/containerd.sock
"
    ]
  }
}
