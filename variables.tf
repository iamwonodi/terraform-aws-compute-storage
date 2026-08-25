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

variable "ami_id" {
  type        = string
  description = "Optional AMI ID to use for the EC2 instance. When null, the module uses the latest matching Ubuntu AMI."

  default = null

  validation {
    condition = (
      var.ami_id == null ||
      trimspace(var.ami_id) != ""
    )

    error_message = "ami_id must be null or a non-empty AMI ID."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."

  default = "t3.medium"

  validation {
    condition     = trimspace(var.instance_type) != ""
    error_message = "instance_type must not be empty."
  }
}

variable "instance_profile_name" {
  type        = string
  description = "Optional IAM instance profile to attach to the EC2 instance."

  default = null

  validation {
    condition = (
      var.instance_profile_name == null ||
      trimspace(var.instance_profile_name) != ""
    )

    error_message = "instance_profile_name must be null or a non-empty string."
  }
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to associate a public IPv4 address with the compute instance."

  default = false
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

variable "root_volume_type" {
  type        = string
  description = "EBS volume type for the root volume."

  default = "gp3"

  validation {
    condition     = contains(["gp3", "gp2"], var.root_volume_type)
    error_message = "root_volume_type must be either gp3 or gp2."
  }
}

variable "user_data" {
  type        = string
  description = "Fully rendered EC2 user-data supplied by the calling module."
  default     = null
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

