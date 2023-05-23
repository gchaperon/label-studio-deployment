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

variable "subdomain" {
  type        = string
  description = "The subdomain name that will be created in var.dns_zone"
  default     = "labelstudio"
}

variable "instance_status" {
  type        = string
  description = "The desired instance status. Either RUNNING or TERMINATED"
  default     = "RUNNING"

  validation {
    condition     = var.instance_status == "RUNNING" || var.instance_status == "TERMINATED"
    error_message = "only RUNNING or TERMINATED allowed"
  }
}
