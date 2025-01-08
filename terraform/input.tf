
variable "node_ips" {
  description = "List of IP addresses for the bare metal nodes"
  type        = list(string)
  default     = ["172.16.8.116", "172.16.8.117"]
}

variable "master_ip" {
  description = "master IP"
  type        = string
  default     = "172.16.8.116"
}
variable "worker_ips" {
  description = "List of IP addresses for the bare metal nodes"
  type        = list(string)
  default     = ["172.16.8.117","172.16.8.118"]
}


variable "ssh_user_name" {
  description = "user name of OS"
  type        = string
  default     = "ubuntu"  
}
variable "ssh_private_key" {
  description = "The private SSH key used to access the nodes"
  type        = string
  default     = "/Users/yangkun/.ssh/ubuntu"  
}
