variable "project_name" {
  type        = string
  description = "Project name used to identify the compute resources."
}

variable "environment" {
  type        = string
  description = "Deployment environment such as development, staging, or production."
}

variable "service_name" {
  type        = string
  description = "Logical service name used to identify the compute and storage resources."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the EC2 instance will be deployed."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID attached to the EC2 instance."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
  default     = "t3.medium"
}

variable "root_volume_size" {
  type        = number
  description = "Encrypted root EBS volume size in GiB."
  default     = 15
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to associate a public IPv4 address with the EC2 instance."
  default     = false
}

variable "enable_route53_write_access" {
  type        = bool
  description = "Whether the EC2 instance IAM role can modify Route 53 records."
  default     = false
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID that the instance IAM role is allowed to modify."
  default     = ""
}

variable "enable_ecr_read_access" {
  type        = bool
  description = "Whether the EC2 instance IAM role can pull images from Amazon ECR."
  default     = false
}

variable "enable_data_volume_mount" {
  type        = bool
  description = "Whether the secondary EBS data volume should be attached and mounted."
  default     = false
}

variable "data_volume_device" {
  type        = string
  description = "Linux device name used for the secondary EBS volume."
  default     = "/dev/sdb"
}


variable "user_data" {
  type        = string
  description = "Fully rendered EC2 user-data supplied by the calling module."
  default     = ""
}