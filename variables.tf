################################################################################
# IDENTIFICATION
################################################################################

variable "project_name" {
  type        = string
  description = "Name of the project consuming the compute-storage module."

  validation {
    condition     = trimspace(var.project_name) != ""
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment such as development, staging, or production."

  validation {
    condition     = trimspace(var.environment) != ""
    error_message = "environment must not be empty."
  }
}

variable "service_name" {
  type        = string
  description = "Logical name of the workload running on the compute instance."

  validation {
    condition     = trimspace(var.service_name) != ""
    error_message = "service_name must not be empty."
  }
}


################################################################################
# NETWORKING
################################################################################

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the EC2 instance will be deployed."

  validation {
    condition     = trimspace(var.subnet_id) != ""
    error_message = "subnet_id must not be empty."
  }
}

variable "security_group_id" {
  type        = string
  description = "Security group ID attached to the EC2 instance."

  validation {
    condition     = trimspace(var.security_group_id) != ""
    error_message = "security_group_id must not be empty."
  }
}


################################################################################
# COMPUTE
################################################################################

variable "instance_type" {
  type        = string
  description = "EC2 instance type."

  default = "t3.medium"

  validation {
    condition     = trimspace(var.instance_type) != ""
    error_message = "instance_type must not be empty."
  }
}

variable "root_volume_size" {
  type        = number
  description = "Size of the encrypted root EBS volume in GiB."

  default = 15

  validation {
    condition     = var.root_volume_size >= 15
    error_message = "root_volume_size must be at least 15 GiB."
  }
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to associate a public IPv4 address with the compute instance."

  default = false
}

variable "user_data" {
  type        = string
  description = "Fully rendered EC2 user-data supplied by the calling module."
}




################################################################################
# ROUTE 53 / IAM
################################################################################

variable "enable_route53_write_access" {
  type        = bool
  description = "Whether the compute instance can modify records in the supplied Route 53 hosted zone."
  default     = false
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID supplied to the compute module when Route 53 write access is enabled."
  default     = ""

  validation {
    condition = (
      var.enable_route53_write_access == false
      ||
      trimspace(var.hosted_zone_id) != ""
    )

    error_message = "hosted_zone_id must be provided when enable_route53_write_access is true."
  }
}


################################################################################
# AMAZON ECR
################################################################################

variable "enable_ecr_read_access" {
  type        = bool
  description = "Whether the compute instance receives IAM permissions required to pull images from Amazon ECR."
  default     = false
}


################################################################################
# SECONDARY EBS STORAGE
################################################################################

variable "enable_data_volume_mount" {
  type        = bool
  description = "Whether to create and attach a secondary persistent EBS volume."

  default = false
}

variable "data_volume_device" {
  type        = string
  description = "Device name exposed to the EC2 operating system for the secondary EBS volume."

  default = "/dev/sdb"

  validation {
    condition     = trimspace(var.data_volume_device) != ""
    error_message = "data_volume_device must not be empty."
  }
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

