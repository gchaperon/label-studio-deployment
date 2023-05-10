terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.64.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}
provider "google" {
  project = var.project
  region  = var.region
}

data "google_dns_managed_zone" "dns_zone" {
  name = var.dns_zone
}

data "google_client_openid_userinfo" "me" {
}

locals {
  ssh_key_list = fileset(pathexpand("~"), ".ssh/id_*.pub")
  ssh_hostname = trimsuffix(google_dns_record_set.label_studio.name, ".")
  username = regex("[^@]*", data.google_client_openid_userinfo.me.email)
}

data "local_file" "ssh_key" {
  filename = "${pathexpand("~")}/${tolist(local.ssh_key_list)[0]}"
  lifecycle {
    precondition {
      condition     = length(local.ssh_key_list) > 0
      error_message = "No pub key found in ~/.ssh"
    }
  }
}


resource "google_dns_record_set" "label_studio" {
  name = "labelstudio.${data.google_dns_managed_zone.dns_zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.dns_zone.name

  rrdatas = [google_compute_instance.label_studio.network_interface[0].access_config[0].nat_ip]
}

resource "google_compute_instance" "label_studio" {
  name         = "label-studio"
  machine_type = "g1-small"
  zone         = "us-central1-b"

  tags = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-105-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata = {
    ssh-keys = join(
      "\n",
      [
        "${local.username}:${trimspace(data.local_file.ssh_key.content)}",
      ]
    )
  }

}
