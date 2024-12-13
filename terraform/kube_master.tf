resource "null_resource" "k8s_master" {
  depends_on = [null_resource.k8s_node]  # 确保裸金属节点创建完成后执行

  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = "root"
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
        
      "kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket=/var/run/containerd/containerd.sock",  # 根据你的网络需求设置适当的CIDR
      "mkdir -p $HOME/.kube",
      "cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "chown $(id -u):$(id -g) $HOME/.kube/config",
      "TOKEN=$(kubeadm token create)",  # 创建 token
      "HASH=$(kubeadm certs ca-cert-hash)",  # 获取 ca-cert-hash
      "echo \"token=$TOKEN hash=$HASH\" > /tmp/kubeadm_info.txt",  # 将信息输出到文件
      "cat /tmp/kubeadm_info.txt"  # 打印出来以便调试
    ]
  }
  triggers = {
    always_run = timestamp()
  }
}

# 输出 token 和 hash，供 worker 节点使用
output "kubeadm_token" {
value = "TOKEN"
}

output "ca_cert_hash" {
value = "HASH"
}
