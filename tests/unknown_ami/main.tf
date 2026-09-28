# Calls the module with an AMI ID that is unknown until apply, as it is when
# the image is built in the same apply as the host. Planned (never applied)
# by tests/plan.tftest.hcl.
terraform {
  required_providers {
    random = { source = "hashicorp/random" }
  }
}

variable "ami_lookup_enabled" {
  type    = bool
  default = null
}

variable "user_data" {
  type    = string
  default = null
}

variable "user_data_replace_on_change" {
  type    = bool
  default = false
}

resource "random_id" "ami" {
  byte_length = 8
}

module "host" {
  source = "../.."

  project_name          = "example"
  environment           = "development"
  service_name          = "database"
  subnet_id             = "subnet-0123456789abcdef0"
  security_group_id     = "sg-0123456789abcdef0"
  instance_type         = "t3.medium"
  instance_profile_name = "example-development-database-profile"

  # The raw attribute: Terraform cannot tell whether it is null until apply.
  ami_id                      = random_id.ami.b64_url
  ami_lookup_enabled          = var.ami_lookup_enabled
  user_data                   = var.user_data
  user_data_replace_on_change = var.user_data_replace_on_change
}
