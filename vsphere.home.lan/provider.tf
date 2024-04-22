provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_pw
  vsphere_server       = "192.168.1.200"
  allow_unverified_ssl = true
}

terraform {
  required_version = "~> 1.8.1"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.7.0"
    }
  }
}