resource "vsphere_datacenter" "homelab_datacenter" {
  name = "homelab"
}

data "vsphere_host_thumbprint" "esxi_host_01_thumbprint" {
  address  = "192.168.1.100"
  insecure = true
}

data "vsphere_host_thumbprint" "esxi_host_02_thumbprint" {
  address  = "192.168.1.110"
  insecure = true
}

data "vsphere_resource_pool" "esxi_host_01_default_resource_pool" {
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
  name          = "esxi-01-default-pool"
}

data "vsphere_resource_pool" "esxi_host_02_default_resource_pool" {
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
  name          = "esxi-02-default-pool"
}

data "vsphere_datastore" "esxi01_hdd_vm_datastore02" {
  name          = "esxi01-hdd-vm-datastore02"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

data "vsphere_datastore" "esxi01_ssd_vm_datastore01" {
  name          = "esxi01-ssd-vm-datastore01"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

data "vsphere_datastore" "esxi02_ssd_vm_datastore01" {
  name          = "esxi02-ssd-vm-datastore01"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

data "vsphere_datastore" "esxi01_hdd_vm_datastore01" {
  name          = "esxi01-hdd-vm-datastore01"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

data "vsphere_network" "vm_network" {
  name          = "VM Network"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

resource "vsphere_content_library" "publisher_content_library" {
  name            = "HomeLab Content Library"
  description     = "A content library for my homelab."
  storage_backing = [data.vsphere_datastore.esxi01_hdd_vm_datastore02.id]
}

resource "vsphere_host" "esxi_host_01" {
  hostname   = "192.168.1.100"
  username   = "root"
  password   = var.vsphere_pw
  datacenter = vsphere_datacenter.homelab_datacenter.moid
  thumbprint = data.vsphere_host_thumbprint.esxi_host_01_thumbprint.id
}

resource "vsphere_host" "esxi_host_02" {
  hostname   = "192.168.1.110"
  username   = "root"
  password   = var.vsphere_pw
  datacenter = vsphere_datacenter.homelab_datacenter.moid
  thumbprint = data.vsphere_host_thumbprint.esxi_host_02_thumbprint.id
}

resource "vsphere_folder" "linux_servers_folder" {
  path          = "Linux Servers"
  type          = "vm"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

resource "vsphere_folder" "playground_folder" {
  path          = "Playground"
  type          = "vm"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

resource "vsphere_folder" "windows_servers_folder" {
  path          = "Windows Servers"
  type          = "vm"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

resource "vsphere_folder" "systems_folder" {
  path          = "Core Systems"
  type          = "vm"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

resource "vsphere_folder" "workstations_folder" {
  path          = "Workstations"
  type          = "vm"
  datacenter_id = vsphere_datacenter.homelab_datacenter.moid
}

resource "vsphere_virtual_machine" "truenas_core" {
  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode
    ]
  }
  folder = "/Core Systems"
  name                       = "TrueNas Core"
  resource_pool_id           = data.vsphere_resource_pool.esxi_host_01_default_resource_pool.id
  datastore_id               = data.vsphere_datastore.esxi01_hdd_vm_datastore01.id
  num_cpus                   = 2
  memory                     = 8192
  guest_id                   = "freebsd14Guest"
  wait_for_guest_net_timeout = 0

  network_interface {
    network_id = data.vsphere_network.vm_network.id
  }

  disk {
    label            = "ssd_disk0"
    unit_number      = 0
    size             = 30
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.esxi01_hdd_vm_datastore01.id
  }

  disk {
    label            = "hdd_disk0"
    unit_number      = 1
    size             = 500
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.esxi01_hdd_vm_datastore01.id
  }

  disk {
    label            = "hdd_disk1"
    unit_number      = 2
    size             = 500
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.esxi01_hdd_vm_datastore02.id
  }
}

resource "vsphere_virtual_machine" "rhel_containers_misc" {
  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode,
      enable_disk_uuid
    ]
  }
  folder = "/Linux Servers"
  name                       = "RHEL 9 - Miscellaneous Containers"
  resource_pool_id           = data.vsphere_resource_pool.esxi_host_02_default_resource_pool.id
  datastore_id               = data.vsphere_datastore.esxi02_ssd_vm_datastore01.id
  num_cpus                   = 2
  memory                     = 8192
  guest_id                   = "rhel9_64Guest"
  wait_for_guest_net_timeout = 0

  network_interface {
    network_id = data.vsphere_network.vm_network.id
  }

  disk {
    label            = "ssd_disk0"
    unit_number      = 0
    size             = 100
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.esxi02_ssd_vm_datastore01.id
  }
}

resource "vsphere_virtual_machine" "rhel_onedev" {
  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode,
      enable_disk_uuid,
      cdrom
    ]
  }
  folder = "/Linux Servers"
  name                       = "RHEL 9 - OneDev"
  resource_pool_id           = data.vsphere_resource_pool.esxi_host_01_default_resource_pool.id
  datastore_id               = data.vsphere_datastore.esxi01_ssd_vm_datastore01.id
  num_cpus                   = 2
  memory                     = 4096
  guest_id                   = "rhel9_64Guest"
  wait_for_guest_net_timeout = 0

  network_interface {
    network_id = data.vsphere_network.vm_network.id
  }

  disk {
    label            = "ssd_disk0"
    unit_number      = 0
    size             = 150
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.esxi01_ssd_vm_datastore01.id
  }
}

resource "vsphere_virtual_machine" "rhel_authentik" {
  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode,
      enable_disk_uuid,
      cdrom
    ]
  }
  folder = "/Linux Servers"
  name                       = "RHEL 9 - Authentik"
  resource_pool_id           = data.vsphere_resource_pool.esxi_host_01_default_resource_pool.id
  datastore_id               = data.vsphere_datastore.esxi01_hdd_vm_datastore01.id
  num_cpus                   = 2
  memory                     = 2048
  guest_id                   = "rhel9_64Guest"
  wait_for_guest_net_timeout = 0

  network_interface {
    network_id = data.vsphere_network.vm_network.id
  }

  disk {
    label            = "ssd_disk0"
    unit_number      = 0
    size             = 50
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.esxi01_hdd_vm_datastore01.id
  }
}

resource "vsphere_virtual_machine" "fedora_citrix_client" {
  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode,
      enable_disk_uuid,
      cdrom
    ]
  }
  folder = "/Workstations"
  name                       = "Fedora 39 Workstation - Citrix Client"
  resource_pool_id           = data.vsphere_resource_pool.esxi_host_01_default_resource_pool.id
  datastore_id               = data.vsphere_datastore.esxi01_ssd_vm_datastore01.id
  num_cpus                   = 2
  memory                     = 2048
  guest_id                   = "fedora64Guest"
  wait_for_guest_net_timeout = 0

  network_interface {
    network_id = data.vsphere_network.vm_network.id
  }

  disk {
    label            = "ssd_disk0"
    unit_number      = 0
    size             = 50
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.esxi01_ssd_vm_datastore01.id
  }
}

resource "vsphere_virtual_machine" "windows_server_2022_dc" {
  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode,
      enable_disk_uuid,
      cdrom
    ]
  }
  folder = "/Windows Servers"
  name                       = "Windows Server 2022 DC"
  resource_pool_id           = data.vsphere_resource_pool.esxi_host_02_default_resource_pool.id
  datastore_id               = data.vsphere_datastore.esxi02_ssd_vm_datastore01.id
  num_cpus                   = 4
  memory                     = 4096
  guest_id                   = "windows2019srvNext_64Guest"
  wait_for_guest_net_timeout = 0

  network_interface {
    network_id = data.vsphere_network.vm_network.id
  }

  disk {
    label            = "ssd_disk0"
    unit_number      = 0
    size             = 125
    thin_provisioned = true
    datastore_id     = data.vsphere_datastore.esxi02_ssd_vm_datastore01.id
  }
}