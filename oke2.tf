# -------------------------------
# OKE Cluster
# -------------------------------
resource "oci_containerengine_cluster" "my_oke_cluster" {
  name               = "my_oke_cluster"
  compartment_id     = var.compartment_id
  vcn_id             = oci_core_vcn.my_vcn.id
  kubernetes_version = "v1.34.1"

  options {
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id           = oci_core_subnet.public_subnet.id
    nsg_ids             = [oci_core_network_security_group.oke_cp_nsg.id]
  }
}

# -------------------------------
# Node Pool (WORKER NODES)
# -------------------------------
resource "oci_containerengine_node_pool" "my_node_pool" {
  name               = "my_node_pool"
  cluster_id         = oci_containerengine_cluster.my_oke_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = oci_containerengine_cluster.my_oke_cluster.kubernetes_version

  node_shape = "VM.Standard.A2.Flex"

  node_shape_config {
    ocpus         = 1
    memory_in_gbs = 8
  }

  node_source_details {
    source_type = "IMAGE"
    image_id    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaandhdevee5m6aid3gmum3pipm6wly5lo5whvegix7wzktmmkss6tq"
  }

  node_config_details {
    size = 1

    nsg_ids = [
      oci_core_network_security_group.oke_workers_nsg.id
    ]

    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.private_subnet.id
    }
  }
}
