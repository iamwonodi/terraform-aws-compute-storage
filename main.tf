
################################################################################
# DATABASE COMPUTE
#
# The database module builds on the reusable compute module.
#
# The compute module remains responsible for:
# - EC2 instance creation
# - IAM instance profile
# - SSM access
# - optional ECR access
# - root volume configuration
#
# This database module is responsible for:
# - database-host-specific configuration
# - database bootstrap
# - database update workflow
# - database workspace configuration
################################################################################

module "compute" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute.git?ref=v1.2.0"

  project_name = var.project_name
  environment  = var.environment
  service_name = var.service_name

  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id

  ami_id                = var.ami_id
  ami_lookup_enabled    = var.ami_lookup_enabled
  instance_type         = var.instance_type
  instance_profile_name = var.instance_profile_name

  associate_public_ip_address = var.associate_public_ip_address

  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  # The caller supplies the rendered script as plain text (see the user_data
  # input); terraform-aws-compute expects it base64-encoded.
  user_data = var.user_data == null ? null : base64encode(var.user_data)
}


# ==============================================================================
# OPTIONAL SECONDARY EBS STORAGE
# ==============================================================================
module "ebs_storage" {
  count        = var.enable_data_volume_mount ? 1 : 0
  source       = "git::https://github.com/iamwonodi/terraform-aws-ebs.git?ref=v1.0.0"
  project_name = var.project_name
  environment  = var.environment
  service_name = var.service_name

  instance_id       = module.compute.instance_id
  availability_zone = module.compute.availability_zone

  device_name = var.data_volume_device
  volume_size = var.data_volume_size
}
