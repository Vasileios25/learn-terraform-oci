resource "oci_core_subnet" "public_subnet" {
  cidr_block                  = "10.0.1.0/24"
  vcn_id                      = oci_core_vcn.my_vcn.id
  compartment_id              = var.compartment_id
  display_name                = "public_subnet"
  dns_label                   = "publicsubnet"

  prohibit_public_ip_on_vnic  = false
  route_table_id              = oci_core_route_table.public_rt.id

  # IMPORTANT: no security lists
}


resource "oci_core_subnet" "private_subnet" {
  cidr_block                  = "10.0.2.0/24"
  vcn_id                      = oci_core_vcn.my_vcn.id
  compartment_id              = var.compartment_id
  display_name                = "private_subnet"
  dns_label                   = "privatesubnet"

  prohibit_public_ip_on_vnic  = true
  route_table_id              = oci_core_route_table.private_rt.id

  # IMPORTANT: no security lists
}
