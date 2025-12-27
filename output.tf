output "k8s_server_ips" {
  description = "Control Plane(s) IP"
  value       = module.k8s_servers.vm_ip
}

output "k8s_worker_ips" {
  description = "Worker(s) IP"
  value       = module.k8s_workers.vm_ip
}

output "custom_hosts_file" {
  description = "Will be appended to /etc/hosts in the VMs"
  value       = local.shared_config.dynamic_hosts
}
