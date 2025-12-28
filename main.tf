locals {
  servers = [
    for i in range(var.count_server) :
    format("%s server%02d server%02d.%s", cidrhost(var.vn_cidr, i + var.start_server_ip), i + 1, i + 1, var.shared_config.net_domain)
  ]

  workers = [
    for i in range(var.count_worker) :
    format("%s worker%02d worker%02d.%s", cidrhost(var.vn_cidr, i + var.start_worker_ip), i + 1, i + 1, var.shared_config.net_domain)
  ]

  shared_config = merge(var.shared_config, {
    shared_dir = "${path.cwd}/sharedDir"
    dynamic_hosts = join("\n", concat(
      ["\n## Control Planes"],
      local.servers,
      ["\n## Workers"],
      local.workers
    ))
    main_cp_ip  = cidrhost(var.vn_cidr, var.start_server_ip)
    user_passwd = var.user_passwd ## keep it sensitive
    #virtual network
    vn_name = var.vn_name
    vn_cidr = var.vn_cidr
    #storage
    storage_name = var.storage_name
    base_os      = data.external.get_vol.result.path == "" ? libvirt_volume.base_os[0].path : data.external.get_vol.result.path
  })

}

data "external" "get_vol" {

  program = ["bash", "${path.root}/scripts/vol-list.sh"]

  query = {
    storage_name = var.storage_name
    base_os_name = var.shared_config.base_os_name
  }

}

# Base cloud image stored in the selected storage pool.
resource "libvirt_volume" "base_os" {

  count = data.external.get_vol.result.path == "" ? 1 : 0

  name   = var.shared_config.base_os_name
  pool   = var.storage_name
  target = { format = { type = "qcow2" }, permissions = { mode = "0666" } }

  create = {
    content = {
      ## from internet
      url = "https://cloud-images.ubuntu.com/releases/noble/release/${var.shared_config.base_os_name}"

      ## from local
      #url = "file://${var.shared_config.base_os_name}"
    }
  }
}

module "k8s_network" {

  source = "./modules/network"

  vn_name = var.vn_name
  vn_cidr = var.vn_cidr

}

module "k8s_servers" {

  source = "./modules/vm"

  depends_on = [
    libvirt_volume.base_os,
    module.k8s_network
  ]

  vm_count  = var.count_server
  hostname  = "server"
  vcpu      = 2
  memory    = 1900        # MiB
  disk_size = 21474836480 # Bytes -> 20GiB

  shared_config = local.shared_config

  #network.tpl
  start_ip = var.start_server_ip

  #kubeadm
  pod_cidr = var.pod_cidr

}

module "k8s_workers" {

  source = "./modules/vm"

  depends_on = [module.k8s_servers]

  vm_count  = var.count_worker
  hostname  = "worker"
  vcpu      = 2
  memory    = 1900        # MiB
  disk_size = 34359738368 # Bytes -> 32GiB

  shared_config = local.shared_config

  #network.tpl
  start_ip = var.start_worker_ip

}
