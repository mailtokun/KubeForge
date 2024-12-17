
variable "node_ips" {
  description = "List of IP addresses for the bare metal nodes"
  type        = list(string)
  default     = ["58.87.95.119", "82.157.11.148"]
}

variable "master_ip" {
  description = "master IP"
  type        = string
  default     = "58.87.95.119"
}
variable "worker_ips" {
  description = "List of IP addresses for the bare metal nodes"
  type        = list(string)
  default     = ["82.157.11.148"]
}


variable "ssh_private_key" {
  description = "The private SSH key used to access the nodes"
  type        = string
  default     = "/Users/yangkun/.ssh/id_rsa_temp.pem"  
}

variable "kubeadm_token" {
  type = string
  default = ""
}

variable "ca_cert_hash" {
  type = string
  default = ""
}

