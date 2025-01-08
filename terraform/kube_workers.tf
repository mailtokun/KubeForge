
# resource "null_resource" "k8s_worker" {
#   depends_on = [null_resource.k8s_network_check]  # 确保Master节点和network插件创建完成后执行   
#   count = length(var.node_ips)-1  # Worker节点

#   connection {
#     type        = "ssh"
#     host        = var.worker_ips[count.index]
#     user        = var.ssh_user_name
#     private_key = file(var.ssh_private_key)
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "echo hello",
#       # "sudo kubeadm join ${var.master_ip}:6443 --token ${output.k8s_token} --discovery-token-ca-cert-hash sha256:${output.k8s_hash} --cri-socket unix:///run/containerd/containerd.sock"
#     ]
#   }
# }



# 从 master 节点获取 token 和证书哈希文件
resource "null_resource" "copy_token_and_hash_to_local" {
  depends_on = [null_resource.k8s_network_check]
  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = var.ssh_user_name
    private_key = file(var.ssh_private_key)
  }

  # provisioner "file" {
  #   source      = "/tmp/kubeadm_token.txt" # 从 master 节点获取 token 文件
  #   destination = "/tmp/kubeadm_token.txt" # 本地存储路径
  # }
  # provisioner "file" {
  #   source      = "/tmp/kubeadm_hash.txt" # 从 master 节点获取 token 文件
  #   destination = "/tmp/kubeadm_hash.txt" # 本地存储路径
  # }

  provisioner "local-exec" {
    command = "scp -i ${var.ssh_private_key} ${var.ssh_user_name}@${var.master_ip}:/tmp/kubeadm_token.txt /tmp/kubeadm_token.txt"
  }

  provisioner "local-exec" {
    command = "scp -i ${var.ssh_private_key}  ${var.ssh_user_name}@${var.master_ip}:/tmp/kubeadm_hash.txt /tmp/kubeadm_hash.txt"
  }

}

# 配置 worker 节点并加入集群
resource "null_resource" "k8s_worker" {
  depends_on = [null_resource.copy_token_and_hash_to_local] # 确保 master 设置完毕，token 文件复制完成
  count = length(var.node_ips)-1  # Worker节点

  connection {
    type        = "ssh"
    host        = var.worker_ips[count.index]
    user        = var.ssh_user_name
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "set -x",
      # 循环遍历 IP 地址并添加到 /etc/hosts 文件
      # "echo '${var.worker_ips[count.index]}    kubenode${count.index}' | sudo tee -a /etc/hosts > /dev/null"

      # 循环遍历 worker_ips 列表并将其添加到 /etc/hosts
      # "for ip in ${join(" ", var.worker_ips)}; do echo \"$ip    kubenode$(index var.worker_ips ip)\" | sudo tee -a /etc/hosts > /dev/null; done",
      # "sudo echo ${var.master_ip} kubemaster >> /etc/hosts",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "set -x",

      "sudo kubeadm reset -f",
      "sudo rm -rf /etc/kubernetes/",
      "sudo rm -rf /var/lib/etcd/",
      "echo $(cat /tmp/kubeadm_token.txt)",
      "echo $(cat /tmp/kubeadm_hash.txt)",
      "sudo kubeadm join ${var.master_ip}:6443 --token ${chomp(file("/tmp/kubeadm_token.txt"))} --discovery-token-ca-cert-hash sha256:${chomp(file("/tmp/kubeadm_hash.txt"))} --cri-socket unix:///run/containerd/containerd.sock --node-name ${var.worker_ips[count.index]} --v=5",
    ]
  }
}
