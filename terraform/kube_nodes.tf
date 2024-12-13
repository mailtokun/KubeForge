# 配置裸金属节点的资源
resource "null_resource" "k8s_node" {
  
  count = 5  # 

  connection {
    type        = "ssh"
    host        = var.node_ips[count.index]
    user        = "root"  # 假设你使用root用户连接
    private_key = file(var.ssh_private_key)  # 私钥路径
  }

  provisioner "remote-exec" {
    inline = [
      "apt update",
      "apt install -y containerd",
      "systemctl enable --now containerd",
      "apt install -y kubelet kubeadm kubectl",
      "systemctl enable kubelet",
      "systemctl start kubelet"
    ]
  }
}
