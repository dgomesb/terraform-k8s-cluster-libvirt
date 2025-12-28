terraform {

  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
  }
}
