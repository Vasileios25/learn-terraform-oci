variable "compartment_id" {
  description = "OCID from your tenancy page"
  type        = string
  default     = "ocid1.tenancy.oc1..aaaaaaaapindjt77s2ei4rrripjaidmijasxf3l5pnfwawayqpqsvlgziauq"
}
variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
  default     = "eu-frankfurt-1"
}

variable "availability_domain"{
  description = "region where you have OCI tenancy"
  type        = string
  default     = "UefU:EU-FRANKFURT-1-AD-1"
}