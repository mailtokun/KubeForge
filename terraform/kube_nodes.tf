# 配置裸金属节点的资源
resource "null_resource" "k8s_node" {
  
  count = length(var.node_ips)  # 

  connection {
    type        = "ssh"
    host        = var.node_ips[count.index]
    user        = "ubuntu"  # 假设你使用root用户连接
    private_key = file(var.ssh_private_key)  # 私钥路径
  }
  provisioner "remote-exec" {
    inline = [
      "rm -f /home/ubuntu/kubectl" # 强制删除旧文件
    ]
  }
  provisioner "file" {
    source      = "/Users/yangkun/dev/src/github.com/mailtokun/KubeForge/kubectl"  # 本地文件路径
    destination = "/home/ubuntu/kubectl"                   # 上传到远程服务器
  }


  provisioner "remote-exec" {
    inline = [
      # 移动 kubectl 文件到系统路径并赋予权限
      "sudo mv /home/ubuntu/kubectl /usr/local/bin/kubectl",
      "sudo chmod +x /usr/local/bin/kubectl",

      
      "sudo apt-get update -y",
      # 安装所需的工具
      "sudo apt-get install -y apt-transport-https ca-certificates curl gpg software-properties-common",
      # 添加 Kubernetes 的官方 apt 仓库
      

      "sudo apt install -y containerd kubelet",
      "sudo systemctl enable --now containerd kubelet",
      
      # 删除现有的 Kubernetes APT 密钥文件
      "sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "sudo echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      # 更新 apt 索引
      "sudo apt-get update -y",
      "sudo apt install -y kubeadm",

          # 验证安装
      "kubectl version --client",
      "kubeadm version",
      "kubelet --version",
      # 禁用所有节点的 swap
      # Kubernetes 假设节点上的内存是独立分配和管理的，而启用 swap 可能导致以下问题：
      # 内存压力问题： 当节点的物理内存不足时，Linux 会将部分内存内容交换到 swap 中。但对于 Kubernetes 来说，如果容器使用的内存被交换到磁盘上，可能会导致节点的响应变慢，影响 Pod 的性能，甚至导致容器崩溃，因为它无法及时获取内存资源。
      # 资源调度的不准确性： Kubernetes 的资源调度和限制是基于内存的实时需求。如果启用了 swap，Kubernetes 可能无法正确评估实际的内存使用情况，导致调度决策不准确，可能出现节点过载或不稳定的情况。
      "sudo swapoff -a",
      #自动启用 IP 转发
      "sudo sysctl -w net.ipv4.ip_forward=1",
      "echo \"net.ipv4.ip_forward = 1\" | sudo tee -a /etc/sysctl.conf > /dev/null",
      "sudo sysctl -p",

      # 重新加载 systemd 配置并重启 kubelet：
      "sudo systemctl daemon-reload",
      "sudo systemctl restart kubelet"

    ]
  }
  triggers = {
    always_run = timestamp()
  }
}
