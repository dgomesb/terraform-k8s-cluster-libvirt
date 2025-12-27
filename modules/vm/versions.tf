terraform {

  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.1"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.4"
    }

  }
}
