output "instance_ip" {
  value       = google_compute_instance.label_studio.network_interface[0].access_config[0].nat_ip
  description = "The ip of the deployed label studio instance"
}

output "label_studio_domain" {
  value       = local.ssh_hostname
  description = "The DNS name of the label studio instance"
}

output "ssh_connect" {
  value       = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${local.username}@${local.ssh_hostname}"
  description = "Use with ssh to connect to instance. Example: ssh $(terraform output -raw ssh_connect)"
}
