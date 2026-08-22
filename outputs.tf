################################################################################
# COMPUTE OUTPUTS
################################################################################

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = module.compute.instance_id
}

output "private_ip" {
  description = "Private IP address of the EC2 instance."
  value       = module.compute.private_ip
}

output "availability_zone" {
  description = "Availability Zone containing the EC2 instance."
  value       = module.compute.availability_zone
}


################################################################################
# STORAGE OUTPUTS
################################################################################

output "data_volume_id" {
  description = "ID of the secondary EBS volume, or null when disabled."
  value       = var.enable_data_volume_mount ? module.ebs_storage[0].volume_id : null
}
