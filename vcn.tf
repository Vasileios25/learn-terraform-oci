resource "oci_core_vcn" "my_vcn" {
  cidr_block     = "10.0.0.0/16"
  display_name   = "my_vcn"
  compartment_id = var.compartment_id
  dns_label      = "internal"
  
}