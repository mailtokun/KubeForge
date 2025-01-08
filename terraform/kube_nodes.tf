# 配置裸金属节点的资源
resource "null_resource" "k8s_node_init" {
  count = length(var.node_ips) # 
  connection {
    type        = "ssh"
    host        = var.node_ips[count.index]
    user        = var.ssh_user_name         # 假设你使用root用户连接
    private_key = file(var.ssh_private_key) # 私钥路径
  }

  provisioner "remote-exec" {
    inline = [
      "set -x", # 打印每一行命令和变量值
      "sudo apt-get update -y",
      # 禁用所有节点的 swap
      # Kubernetes 假设节点上的内存是独立分配和管理的，而启用 swap 可能导致以下问题：
      # 内存压力问题： 当节点的物理内存不足时，Linux 会将部分内存内容交换到 swap 中。但对于 Kubernetes 来说，如果容器使用的内存被交换到磁盘上，可能会导致节点的响应变慢，影响 Pod 的性能，甚至导致容器崩溃，因为它无法及时获取内存资源。
      # 资源调度的不准确性： Kubernetes 的资源调度和限制是基于内存的实时需求。如果启用了 swap，Kubernetes 可能无法正确评估实际的内存使用情况，导致调度决策不准确，可能出现节点过载或不稳定的情况。
      "sudo swapoff -a",
      #自动启用 IP 转发
      "sudo sysctl -w net.ipv4.ip_forward=1",
      "echo \"net.ipv4.ip_forward = 1\" | sudo tee -a /etc/sysctl.conf > /dev/null",
      "sudo sysctl -p",
      # 安装所需的工具
      "sudo apt-get install -y apt-transport-https ca-certificates curl gpg software-properties-common",
    ]
  }
  triggers = {
    always_run = timestamp()
  }
}
resource "null_resource" "k8s_node_cri" {
  count = length(var.node_ips) # 
  connection {
    type        = "ssh"
    host        = var.node_ips[count.index]
    user        = var.ssh_user_name         # 假设你使用root用户连接
    private_key = file(var.ssh_private_key) # 私钥路径
  }
  provisioner "remote-exec" {
    inline = [
      "set -x", # 打印每一行命令和变量值
      # 安装容器运行时（Containerd）
      # 添加 Docker 官方的 GPG 密钥
      "sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      # 添加 Docker 的 apt 仓库
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list",
      "sudo apt-get update",
      "sudo apt-get install -y containerd.io",
      # 配置 Containerd 使用 systemd cgroup 驱动
      "sudo mkdir -p /etc/containerd",
      "containerd config default | sudo tee /etc/containerd/config.toml > /dev/null",
      "sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml",
      # 重启 Containerd
      "sudo systemctl restart containerd",
      "sudo systemctl enable containerd",
    ]
  }
  triggers = {
    always_run = timestamp()
  }
  depends_on = [null_resource.k8s_node_init]
}
resource "null_resource" "k8s_node_kubetools" {
  count = length(var.node_ips) # 
  connection {
    type        = "ssh"
    host        = var.node_ips[count.index]
    user        = var.ssh_user_name         # 假设你使用root用户连接
    private_key = file(var.ssh_private_key) # 私钥路径
  }
  provisioner "remote-exec" {
    inline = [
      "set -x", # 打印每一行命令和变量值
      "if ! grep -q '^nameserver 8.8.8.8' /etc/resolv.conf; then sudo sed -i '1inameserver 8.8.8.8' /etc/resolv.conf && echo 'Successfully added nameserver 8.8.8.8 to the first line of /etc/resolv.conf'; else echo 'nameserver 8.8.8.8 is already present in /etc/resolv.conf, no changes made.'; fi",
      # 添加 Kubernetes 的官方 apt 仓库
      "sudo mkdir -p -m 755 /etc/apt/keyrings",
      "sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y kubeadm kubectl kubelet --allow-change-held-packages",
      "sudo apt-mark hold kubelet kubeadm kubectl",
      "sudo systemctl enable --now kubelet",
      # 验证安装
      "kubectl version --client",
      "kubeadm version",
      "kubelet --version",

      # 重新加载 systemd 配置并重启 kubelet：
      "sudo systemctl daemon-reload",
      "sudo systemctl restart kubelet"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
  depends_on = [null_resource.k8s_node_cri]
}
