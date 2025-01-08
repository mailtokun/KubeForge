resource "null_resource" "k8s_master" {
  depends_on = [null_resource.k8s_node_kubetools] # 确保裸金属节点创建完成后执行

  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = var.ssh_user_name
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "set -x", # 打印每一行命令和变量值
      "sudo kubeadm reset -f",
      "sudo rm -rf /etc/kubernetes/",
      "sudo rm -rf /var/lib/etcd/",
      "sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --image-repository=registry.k8s.io --cri-socket unix:///run/containerd/containerd.sock",
      # "sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket=unix:///var/run/containerd/containerd.sock",  # 根据你的网络需求设置适当的CIDR
      "sudo mkdir -p $HOME/.kube",
      "sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "echo $(kubeadm token create) > /tmp/kubeadm_token.txt",                                                                                                                      # 将 token 输出到文件
      "openssl x509 -pubkey -noout -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform DER 2>/dev/null | openssl dgst -sha256 | awk '{print $2}' > /tmp/kubeadm_hash.txt", # 将 hash 输出到文件
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "set -x",
      # 循环遍历 IP 地址并添加到 /etc/hosts 文件
      # "echo '${var.worker_ips[count.index]}    kubenode${count.index}' | sudo tee -a /etc/hosts > /dev/null"

      # 循环遍历 worker_ips 列表并将其添加到 /etc/hosts
      # "for ip in ${join(" ", var.worker_ips)}; do echo \"$ip    kubenode$(index var.worker_ips ip)\" | sudo tee -a /etc/hosts > /dev/null; done"
    ]
  }


  triggers = {
    always_run = timestamp()
  }
}
