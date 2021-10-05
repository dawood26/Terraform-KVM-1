terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    }
  }
}
#provider "libvirt" {
  #uri = "qemu:///system"
#}

provider "libvirt" {
 alias = "server2"
 uri   = "qemu+ssh://root@192.168.122.1/system"
}
resource "libvirt_volume" "server1-qcow2" {
  name = "server1.qcow2"
  pool = "default"
  source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  #source = "./cloudimage/CentOS-8-GenericCloud-8.3.2011-20201204.2.x86_64.qcow2"
  format = "qcow2"
}

data "template_file" "user_data" {
  #template = "${file("${path.module}/cloud_init.cfg")}"
  template = file("./cloud_init.cfg")
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit-server1" {
  name           = "commoninit-server1.iso"
  user_data      = data.template_file.user_data.rendered
}
resource "libvirt_domain" "server1" {
  name   = "server1"
  memory = "2048"
  vcpu   = 2
  network_interface {
    network_name = "default"
  }
  disk {
    volume_id = libvirt_volume.server1-qcow2.id
  }
  cloudinit = libvirt_cloudinit_disk.commoninit-server1.id

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}
output "ip1" {
  value = libvirt_domain.server1.network_interface.0.addresses.0
}



