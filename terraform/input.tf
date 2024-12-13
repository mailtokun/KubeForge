
variable "node_ips" {
  description = "List of IP addresses for the bare metal nodes"
  type        = list(string)
  default     = ["192.168.1.10", "192.168.1.11", "192.168.1.12", "192.168.1.13", "192.168.1.14"]
}

variable "master_ip" {
  description = "master IP"
  type        = string
  default     = "192.168.1.10"
}
variable "worker_ips" {
  description = "List of IP addresses for the bare metal nodes"
  type        = list(string)
  default     = ["192.168.1.11", "192.168.1.12", "192.168.1.13", "192.168.1.14"]
}


variable "ssh_private_key" {
  description = "The private SSH key used to access the nodes"
  type        = string
  default     = "~/.ssh/id_rsa"  # 替换为你的SSH私钥路径
}

variable "kubeadm_token" {
  type = string
}

variable "ca_cert_hash" {
  type = string
}

