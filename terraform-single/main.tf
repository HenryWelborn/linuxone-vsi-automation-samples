
# Create a VPC
resource "ibm_is_vpc" "testacc_vpc" {
  name = var.vpc
}

# RSA key of size 2048 bits
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Write out the OpenSSH private key
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = var.ssh_private_keyfile
  file_permission = "0600"
}

# Write out the OpenSSH public key
resource "local_file" "public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = var.ssh_public_keyfile
  file_permission = "0644"
}

# ssh key onto IBM Cloud
resource "ibm_is_ssh_key" "testacc_sshkey" {
  name      = var.ssh_public_key_name
  public_key = trimspace(tls_private_key.ssh.public_key_openssh)
}

# subnetwork
resource "ibm_is_subnet" "testacc_subnet" {
  name                     = var.subnetwork_name
  vpc                      = ibm_is_vpc.testacc_vpc.id
  zone                     = local.full_zone
  total_ipv4_address_count = var.total_ipv4_address_count
}

# security group
resource "ibm_is_security_group" "testacc_security_group" {
  name = var.vsi_name
  vpc = ibm_is_vpc.testacc_vpc.id
}

# rule that allows the VSI to make outbound connections, this is required
# to connect to the logDNA instance as well as to docker to pull the image
resource "ibm_is_security_group_rule" "testacc_security_group_rule_outbound" {
  group     = ibm_is_security_group.testacc_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Configure Security Group Rule to open SSH
resource "ibm_is_security_group_rule" "testacc_security_group_rule_ssh" {
  group = ibm_is_security_group.testacc_security_group.id
  direction = "inbound"
  remote = "0.0.0.0/0"
  # tcp {
  #   port_min = 22
  #   port_max = 22
  # }
}

# Images
data "ibm_is_images" "vpc_images" {
}
locals {
  image = [for image in data.ibm_is_images.vpc_images.images : image if length(regexall(local.image_name, image.name)) > 0][0]
}

# vsi
resource "ibm_is_instance" "testacc_vsi" {
  name    = local.randomized_vsi_name
  image   = local.image.id
  profile = local.profile

  primary_network_interface {
    subnet = ibm_is_subnet.testacc_subnet.id
    security_groups = [ibm_is_security_group.testacc_security_group.id]
  }

  vpc  = ibm_is_vpc.testacc_vpc.id
  zone = "${var.region}-${var.zone}"
  keys = [ibm_is_ssh_key.testacc_sshkey.id]
}

# Floating IP
resource "ibm_is_floating_ip" "testacc_floatingip" {
  name   = var.vsi_name
  target = ibm_is_instance.testacc_vsi.primary_network_interface[0].id
}

# log the floating IP for convenience
output "ip" {
  value = resource.ibm_is_floating_ip.testacc_floatingip.address
  description = "The public IP address of the VSI" 
}
