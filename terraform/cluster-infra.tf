terraform {
  required_version = ">=0.14"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "ubuntu_22_04_cloud" {
  name   = "ubuntu22.04.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "ubuntu_22_04_resized" {
  name           = "ubuntu-volume-${count.index}"
  base_volume_id = libvirt_volume.ubuntu_22_04_cloud.id
  pool           = "default"
  size           = 42949672960
  count          = 3
}

resource "libvirt_cloudinit_disk" "cloudinit_k8s_controlplane" {
  name = "cloudinit_ubuntu_k8s_controlplane.iso"
  pool = "default"

  user_data = <<EOF
#cloud-config
disable_root: 0
ssh_pwauth: 1
users:
  - name: ubuntu
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${file("~/.ssh/sol.key.pub")}
growpart:
  mode: auto
  devices: ['/']
hostname: k8s-controlplane
fqdn: k8s-controlplane.k8s.local
EOF
}

resource "libvirt_cloudinit_disk" "cloudinit_k8s_node_1" {
  name = "cloudinit_ubuntu_k8s_node_1.iso"
  pool = "default"

  user_data = <<EOF
#cloud-config
disable_root: 0
ssh_pwauth: 1
users:
  - name: ubuntu
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${file("~/.ssh/sol.key.pub")}
growpart:
  mode: auto
  devices: ['/']
hostname: k8s-node-1
fqdn: k8s-node-1.k8s.local
EOF
}

resource "libvirt_cloudinit_disk" "cloudinit_k8s_node_2" {
  name = "cloudinit_ubuntu_k8s_node_2.iso"
  pool = "default"

  user_data = <<EOF
#cloud-config
disable_root: 0
ssh_pwauth: 1
users:
  - name: ubuntu
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${file("~/.ssh/sol.key.pub")}
growpart:
  mode: auto
  devices: ['/']
hostname: k8s-node-2
fqdn: k8s-node-2.k8s.local
EOF
}


resource "libvirt_network" "kube_network" {
  name      = "k8snet"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = ["172.16.1.0/24"]
  dns {
    enabled = true
  }
}

resource "libvirt_domain" "k8s-controlplane" {
  name   = "k8s-controlplane"
  memory = "4096"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.cloudinit_k8s_controlplane.id

  network_interface {
    network_id     = libvirt_network.kube_network.id
    hostname       = "k8s-controlplane"
    addresses      = ["172.16.1.11"]
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.ubuntu_22_04_resized[0].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  connection {
    type     = "ssh"
    user     = "ubuntu"
    host     = self.network_interface[0].addresses[0]
    private_key = "${file("~/.ssh/sol.key")}"
  }

  provisioner "remote-exec" {
    inline = ["sudo sed -i 's/localhost/k8s-controlplane/' /etc/hosts"]
  }
}

output "ip-controlplane" {
  value = libvirt_domain.k8s-controlplane.network_interface[0].addresses[0]
}

resource "libvirt_domain" "k8s-node-1" {
  name   = "k8s-node-1"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.cloudinit_k8s_node_1.id

  network_interface {
    network_id     = libvirt_network.kube_network.id
    hostname       = "k8s-node-1"
    addresses      = ["172.16.1.21"]
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.ubuntu_22_04_resized[1].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  connection {
    type     = "ssh"
    user     = "ubuntu"
    host     = self.network_interface[0].addresses[0]
    private_key = "${file("~/.ssh/sol.key")}"
  }

  provisioner "remote-exec" {
    inline = ["sudo sed -i 's/localhost/k8s-node-1/' /etc/hosts"]
  }
}

output "ip-node-1" {
  value = libvirt_domain.k8s-node-1.network_interface[0].addresses[0]
}

resource "libvirt_domain" "k8s-node-2" {
  name   = "k8s-node-2"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.cloudinit_k8s_node_2.id

  network_interface {
    network_id     = libvirt_network.kube_network.id
    hostname       = "k8s-node-2"
    addresses      = ["172.16.1.22"]
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.ubuntu_22_04_resized[2].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  connection {
    type     = "ssh"
    user     = "ubuntu"
    host     = self.network_interface[0].addresses[0]
    private_key = "${file("~/.ssh/sol.key")}"
  }

  provisioner "remote-exec" {
    inline = ["sudo sed -i 's/localhost/k8s-node-2/' /etc/hosts"]
  }
}

output "ip-node-2" {
  value = libvirt_domain.k8s-node-2.network_interface[0].addresses[0]
}

terraform {
  required_version = ">= 0.15"
}
