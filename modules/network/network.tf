locals {
  dhcp_start_ip = cidrhost(var.vn_cidr, 241)
  dhcp_end_ip   = cidrhost(var.vn_cidr, 254)
  mtu_size      = 1500
}

resource "libvirt_network" "virtual_network" {

  name      = var.vn_name
  autostart = true
  forward   = { mode = "nat", nat = { ports = [{ start = 1024, end = 65535 }] } }
  mtu       = { size = local.mtu_size }
  ips = [{
    address = cidrhost(var.vn_cidr, 1)
    prefix  = split("/", var.vn_cidr)[1]
    #netmask = "255.255.255.0"
    dhcp = {
      ranges = [{
        start = local.dhcp_start_ip
        end   = local.dhcp_end_ip
        lease = { expiry = 1, unit = "hours" }
      }]
    }
  }]
}
