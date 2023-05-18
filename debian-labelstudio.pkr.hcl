packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "project" {
  type = string
  description = "The gcp project where the images will be hosted."
}

variable "certificate_email" {
  type = string
  description = "The image will generate ssl keys for https. This is the email associated with the agreement of the TOS of letsencrypt"
}

variable "domain_name" {
  type = string
  description = "The domain name for the ssl certificates"
}

source "googlecompute" "labelstudio" {
  project_id   = var.project
  source_image_family = "debian-11"
  image_family = "labelstudio"
  machine_type = "n2-standard-4"
  ssh_username = "packer"
  zone         = "us-central1-a"

}

build {
  name    = "labelstudio"
  sources = ["source.googlecompute.labelstudio"]

  provisioner "file" {
    source = "docker-compose.yaml"
    destination = "/tmp/"
  }
  provisioner "file" {
    source = "labelstudio.conf"
    destination = "/tmp/"
  }

  provisioner "shell" {
    env = {
      CERTBOT_EMAIL = var.certificate_email
      CERTBOT_DOMAIN = var.domain_name
    }
    script = "provision.sh"
  }
}

