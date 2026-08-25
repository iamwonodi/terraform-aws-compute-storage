module "compute_storage" {
  source = "../../"

  project_name = var.project_name
  environment  = var.environment
  service_name = var.service_name

  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id

  instance_type         = var.instance_type
  instance_profile_name = var.instance_profile_name

  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  associate_public_ip_address = var.associate_public_ip_address

  enable_data_volume_mount = var.enable_data_volume_mount
  data_volume_device       = var.data_volume_device
  data_volume_size         = var.data_volume_size

  user_data = var.user_data
}