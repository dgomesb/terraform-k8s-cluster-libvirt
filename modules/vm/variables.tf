variable "vm_count" { type = number }
variable "hostname" { type = string }
variable "vcpu" { type = number }
variable "memory" { type = number }
variable "vm_disk_size" { type = number }

variable "shared_config" {
  type = object({
    shared_dir    = string
    dynamic_hosts = string
    main_cp_ip    = string
    #virtual network
    vn_name = string
    vn_cidr = string
    # storage
    storage_name = string
    base_os      = string
    #userdata.tpl
    user_name       = string
    user_passwd     = string
    user_ssh_pub    = string
    timezone        = string
    locale          = string
    kubeadm_version = string
    #network.tpl
    net_domain = string
  })
}

variable "start_ip" { type = number }

#kubeadm
variable "pod_cidr" {
  type    = string
  default = ""
}
