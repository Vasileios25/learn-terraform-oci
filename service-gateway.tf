#fetches all OCI service CIDRs available in region
data "oci_core_services" "all_services" {}


#From the list of all OCI services, find the one whose name looks like
All <something> Services in Oracle Services Network
data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}


#creates a private gateway inside my VCN
resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.my_vcn.id
  display_name   = "oke_service_gateway"

  services {
    service_id = lookup(data.oci_core_services.all_oci_services.services[0], "id")
  }
}