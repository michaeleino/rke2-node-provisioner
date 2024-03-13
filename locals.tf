locals {
  target_ip = var.target_ip
  role = (var.role == "server" ? "--etcd --controlplane" : "--worker")
  insecure_node_command = var.insecure_node_command
  os_user = var.os_user
}