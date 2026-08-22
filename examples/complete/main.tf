module "compute_storage" {
  source = "../../"

  project_name = var.project_name
  environment  = var.environment
  service_name = var.service_name

  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id

  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size

  associate_public_ip_address = var.associate_public_ip_address

  enable_route53_write_access = var.enable_route53_write_access
  hosted_zone_id              = var.hosted_zone_id

  enable_ecr_read_access = var.enable_ecr_read_access

  enable_data_volume_mount = var.enable_data_volume_mount
  data_volume_device       = var.data_volume_device

  user_data = var.user_data
}