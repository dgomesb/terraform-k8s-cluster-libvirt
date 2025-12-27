#output "vm_ip" {
#  description = "Show IPs when using DHCP"
#  value = {
#    for i in range(var.count_nodes) :
#    libvirt_domain.vm[i].name => data.libvirt_domain_interface_addresses.vm[i].interfaces[0].addrs[0].addr
#  }
#}

output "vm_ip" {
  value = {
    for i in range(var.vm_count) :
    libvirt_domain.vm[i].name => format("%s/%s", cidrhost(var.shared_config.vn_cidr, i + var.start_ip), split("/", var.shared_config.vn_cidr)[1])
  }
}
