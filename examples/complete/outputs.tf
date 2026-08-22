output "instance_id" {
  description = "ID of the EC2 instance."
  value       = module.compute_storage.instance_id
}

output "private_ip" {
  description = "Private IP address of the EC2 instance."
  value       = module.compute_storage.private_ip
}

output "availability_zone" {
  description = "Availability Zone containing the EC2 instance."
  value       = module.compute_storage.availability_zone
}

output "data_volume_id" {
  description = "ID of the attached persistent EBS data volume, or null when disabled."
  value       = module.compute_storage.data_volume_id
}