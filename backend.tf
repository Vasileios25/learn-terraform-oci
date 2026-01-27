terraform {
  backend "oci" {
    bucket    = "bucket-state"
    key       = "State/OKE.tfstate"
    namespace = "frgrrigu4nsa"
    region    = "eu-frankfurt-1"
    auth      = "APIKey"
  }
}


