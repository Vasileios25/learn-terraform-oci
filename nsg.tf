resource "oci_core_network_security_group" "oke_cp_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.my_vcn.id
  display_name   = "oke-control-plane-nsg"
}

# Workers → API server (6443)
resource "oci_core_network_security_group_security_rule" "cp_ingress_6443" {
  network_security_group_id = oci_core_network_security_group.oke_cp_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                     = oci_core_subnet.private_subnet.cidr_block
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

# Workers → control plane (12250)
resource "oci_core_network_security_group_security_rule" "cp_ingress_12250" {
  network_security_group_id = oci_core_network_security_group.oke_cp_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                     = oci_core_subnet.private_subnet.cidr_block
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 12250
      max = 12250
    }
  }
}

# Control plane → workers (all TCP)
resource "oci_core_network_security_group_security_rule" "cp_egress_workers" {
  network_security_group_id = oci_core_network_security_group.oke_cp_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_subnet.private_subnet.cidr_block
  destination_type          = "CIDR_BLOCK"
}





resource "oci_core_network_security_group" "oke_workers_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.my_vcn.id
  display_name   = "oke-workers-nsg"
}

# API server → workers (6443)
resource "oci_core_network_security_group_security_rule" "workers_ingress_6443" {
  network_security_group_id = oci_core_network_security_group.oke_workers_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                     = oci_core_subnet.public_subnet.cidr_block
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

# Control plane → kubelet (12250)
resource "oci_core_network_security_group_security_rule" "workers_ingress_12250" {
  network_security_group_id = oci_core_network_security_group.oke_workers_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                     = oci_core_subnet.public_subnet.cidr_block
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 12250
      max = 12250
    }
  }
}

# Pod-to-pod traffic
resource "oci_core_network_security_group_security_rule" "workers_ingress_pods" {
  network_security_group_id = oci_core_network_security_group.oke_workers_nsg.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source                     = oci_core_subnet.private_subnet.cidr_block
  source_type               = "CIDR_BLOCK"
}

# Workers → control plane (6443)
resource "oci_core_network_security_group_security_rule" "workers_egress_6443" {
  network_security_group_id = oci_core_network_security_group.oke_workers_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_subnet.public_subnet.cidr_block
  destination_type          = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

# Workers → control plane (12250)
resource "oci_core_network_security_group_security_rule" "workers_egress_12250" {
  network_security_group_id = oci_core_network_security_group.oke_workers_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_subnet.public_subnet.cidr_block
  destination_type          = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 12250
      max = 12250
    }
  }
}

# Workers → Internet (via NAT)
resource "oci_core_network_security_group_security_rule" "workers_egress_all" {
  network_security_group_id = oci_core_network_security_group.oke_workers_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}
