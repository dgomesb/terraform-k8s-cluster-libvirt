resource "libvirt_volume" "disk" {

  count = var.vm_count

  name     = format("%s%02d.qcow2", var.hostname, count.index + 1)
  pool     = var.shared_config.storage_name
  target   = { format = { type = "qcow2" }, permissions = { mode = "0666" } }
  capacity = var.disk_size
  #capacity_unit = "MiB" ## not working. Default in Bytes

  backing_store = {
    path   = var.shared_config.base_os
    format = { type = "qcow2" }
  }

}

resource "libvirt_cloudinit_disk" "cloudinit" {

  count = var.vm_count

  name = format("%s%02d-init.iso", var.hostname, count.index + 1)

  user_data = templatefile("${path.module}/config/userdata.tpl", {
    hostname        = format("%s%02d", var.hostname, count.index + 1)
    fqdn            = format("%s%02d.%s", var.hostname, count.index + 1, var.shared_config.net_domain)
    user_name       = var.shared_config.user_name
    user_passwd     = var.shared_config.user_passwd
    user_ssh_pub    = var.shared_config.user_ssh_pub
    timezone        = var.shared_config.timezone
    locale          = var.shared_config.locale
    kubeadm_version = var.shared_config.kubeadm_version
    dynamic_hosts   = indent(6, var.shared_config.dynamic_hosts)
    myKubeadm = indent(6, templatefile("${path.module}/config/myKubeadm.sh", {
      pod_cidr   = var.pod_cidr
      main_cp_ip = var.shared_config.main_cp_ip
    }))
  })

  meta_data = yamlencode({
    instance-id    = format("%s%02d", var.hostname, count.index + 1)
    local-hostname = format("%s%02d.%s", var.hostname, count.index + 1, var.shared_config.net_domain)
  })

  network_config = templatefile("${path.module}/config/network.tpl", {
    ip_addr    = cidrhost(var.shared_config.vn_cidr, count.index + var.start_ip)
    ip_mask    = split("/", var.shared_config.vn_cidr)[1]
    ip_gw      = cidrhost(var.shared_config.vn_cidr, 1)
    net_domain = var.shared_config.net_domain
  })

}

resource "libvirt_volume" "cloudinit" {

  count = var.vm_count

  name   = format("%s%02d-init.iso", var.hostname, count.index + 1)
  pool   = var.shared_config.storage_name
  target = { format = { type = "iso" }, permissions = { mode = "0644" } }

  create = { content = { url = libvirt_cloudinit_disk.cloudinit[count.index].path } }
}
