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

variable "instance_profile_name" {
  type        = string
  description = "Optional IAM instance profile to attach to the EC2 instance."

  default = null
}

variable "root_volume_size" {
  type        = number
  description = "Encrypted root EBS volume size in GiB."
  default     = 15
}

variable "root_volume_type" {
  type        = string
  description = "EBS volume type for the root volume."

  default = "gp3"

  validation {
    condition     = contains(["gp3", "gp2"], var.root_volume_type)
    error_message = "root_volume_type must be either gp3 or gp2."
  }
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to associate a public IPv4 address with the EC2 instance."
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


variable "data_volume_size" {
  type        = number
  description = "Size of the secondary EBS volume in GiB."

  default = 50

  validation {
    condition     = var.data_volume_size >= 1
    error_message = "data_volume_size must be at least 1 GiB."
  }
}

variable "user_data" {
  type        = string
  description = "Fully rendered EC2 user-data supplied by the calling module."
  default     = ""
}