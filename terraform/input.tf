
variable "node_ips" {
  description = "List of IP addresses for the bare metal nodes"
  type        = list(string)
}

variable "master_ip" {
  description = "master IP"
  type        = string
}
variable "worker_ips" {
  description = "List of IP addresses for the bare metal nodes"
  type        = list(string)
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
