resource "null_resource" "k8s_network" {
  depends_on = [null_resource.k8s_master]

  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = var.ssh_user_name
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "set -x", # 打印每一行命令和变量值
      "export KUBECONFIG=$HOME/.kube/config",
      "sudo -E kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml",
      "sudo -E kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml",
      "sudo -E kubectl get pods -n kube-system"
    ]
  }
}
resource "null_resource" "k8s_network_check" {
  depends_on = [null_resource.k8s_network]

  connection {
    type        = "ssh"
    host        = var.master_ip
    user        = var.ssh_user_name
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "set -x", # 打印每一行命令和变量值
      "MAX_RETRIES=30",    # 最大重试次数
      "SLEEP_INTERVAL=10", # 每次检查的间隔时间（秒）",
      "for i in $(seq 1 $MAX_RETRIES); do",
      "  echo \"Checking Calico Pods status (Attempt $i)...\"",
      "  STATUS=$(kubectl get pods -n calico-system --no-headers | awk '{print $3}' | grep -v Running || true)",
      "  if [ -z \"$STATUS\" ]; then",
      "    echo \"All Calico Pods are Running.\"",
      "    exit 0",
      "  else",
      "    echo \"Some pods are not Running. Retrying in $SLEEP_INTERVAL seconds...\"",
      "    sleep $SLEEP_INTERVAL",
      "  fi",
      "done",
      "echo \"Timeout waiting for Calico Pods to be Running.\"",
      "exit 1"
    ]
  }
}
