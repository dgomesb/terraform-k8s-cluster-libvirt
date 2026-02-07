terraform {

  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.2"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }

  }
}
