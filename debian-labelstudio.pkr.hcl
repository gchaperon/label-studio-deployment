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

  provisioner "shell" {
    script = "provision.sh"
  }
}
