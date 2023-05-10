variable "project" {
  type        = string
  description = "The gcp project id"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The gcp region"
}

variable "dns_zone" {
  type        = string
  description = "The domain name under which the label studio subdomain will be created."
}




