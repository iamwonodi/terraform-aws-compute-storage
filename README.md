# Terraform AWS Compute Storage

Reusable Terraform module for provisioning an EC2 compute instance with optional persistent EBS storage.

The module builds on the reusable `terraform-aws-compute` module and optionally attaches a separate `terraform-aws-ebs` volume to the created instance.

## Architecture

```text
                    ┌──────────────────────────────┐
                    │        Calling Module        │
                    │                              │
                    │ project / environment /      │
                    │ service / networking /       │
                    │ compute configuration        │
                    └──────────────┬───────────────┘
                                   │
                                   │ module inputs
                                   ▼
                    ┌──────────────────────────────┐
                    │      Compute Storage         │
                    │                              │
                    │  terraform-aws-compute      │
                    │          │                   │
                    │          ▼                   │
                    │      EC2 Instance             │
                    │                              │
                    │          │                   │
                    │          ▼                   │
                    │  Optional EBS Storage        │
                    │  terraform-aws-ebs           │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
             EC2 Instance                  EBS Volume
             - Private IP                  - Persistent
             - IAM role                    - Encrypted
             - Root volume                 - gp3
             - SSM access                  - Attached to EC2
             - Optional ECR
             - Optional Route 53
```

## What this module does

This module provides a higher-level composition of two reusable modules:

* `terraform-aws-compute`
* `terraform-aws-ebs`

The compute module creates and manages the EC2 instance and its associated IAM configuration.

The EBS module creates and attaches an independent persistent EBS volume when enabled.

This separation keeps compute and persistent storage independently reusable while allowing applications that need both to consume a single module.

## Responsibilities

### Compute

The underlying compute module is responsible for:

* EC2 instance creation
* Instance type
* Root EBS volume
* Security group association
* Subnet placement
* SSM access
* IAM instance profile
* Optional Route 53 write permissions
* Optional ECR read permissions
* EC2 user data

### Storage

The optional EBS module is responsible for:

* Persistent EBS volume creation
* EBS volume encryption
* EBS volume type and performance configuration
* Volume attachment
* Persistent volume lifecycle

The storage volume is created only when:

```hcl
enable_data_volume_mount = true
```

## Module source

Example:

```hcl
module "compute_storage" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute-storage.git?ref=v1.0.0"

  project_name = "mavis"
  environment  = "development"
  service_name = "database"

  subnet_id         = module.vpc_base.isolated_subnet_ids[0]
  security_group_id = module.internal_sg.security_group_id

  instance_type    = "t3.medium"
  root_volume_size = 20

  enable_route53_write_access = true
  hosted_zone_id              = module.dns_acm.private_zone_id

  enable_ecr_read_access = true

  enable_data_volume_mount = true
}
```

## Compute configuration

### `project_name`

Identifies the project consuming the module.

```hcl
project_name = "mavis"
```

### `environment`

Identifies the deployment environment.

```hcl
environment = "development"
```

### `service_name`

Logical name of the workload.

```hcl
service_name = "database"
```

### `subnet_id`

Subnet where the EC2 instance is deployed.

```hcl
subnet_id = module.vpc_base.isolated_subnet_ids[0]
```

### `security_group_id`

Security group attached to the EC2 instance.

```hcl
security_group_id = module.internal_sg.security_group_id
```

### `instance_type`

EC2 instance type.

Default:

```hcl
instance_type = "t3.medium"
```

Example:

```hcl
instance_type = "t3.large"
```

### `root_volume_size`

Size of the EC2 root volume in GiB.

Default:

```hcl
root_volume_size = 15
```

Example:

```hcl
root_volume_size = 30
```

## Route 53 permissions

The module supports optional Route 53 write access through the underlying compute module.

### `enable_route53_write_access`

Controls whether the EC2 instance IAM role receives permission to modify Route 53 records.

Default:

```hcl
enable_route53_write_access = false
```

Enable it when the workload needs to perform private DNS registration or other Route 53 record changes.

```hcl
enable_route53_write_access = true
```

### `hosted_zone_id`

The Route 53 hosted zone to which the compute instance is granted write access.

```hcl
hosted_zone_id = module.dns_acm.private_zone_id
```

These two settings are intentionally passed through to the underlying compute module:

```hcl
enable_route53_write_access = var.enable_route53_write_access
hosted_zone_id              = var.hosted_zone_id
```

The compute-storage module does not itself perform Route 53 registration. It exposes the capability provided by the underlying compute module.

## Amazon ECR permissions

### `enable_ecr_read_access`

Controls whether the EC2 instance receives permissions required to authenticate to and pull images from Amazon ECR.

Default:

```hcl
enable_ecr_read_access = false
```

Example:

```hcl
enable_ecr_read_access = true
```

This is passed directly to the underlying compute module:

```hcl
enable_ecr_read_access = var.enable_ecr_read_access
```

## User data

### `user_data`

The module accepts fully rendered EC2 user data from the caller.

```hcl
user_data = local.database_user_data
```

The compute-storage module does not impose an application-specific bootstrap implementation.

This allows the caller to control:

* operating-system configuration
* Docker installation
* application deployment
* database configuration
* service discovery
* secrets integration
* storage mounting
* application-specific initialization

For example:

```hcl
locals {
  database_user_data = templatefile(
    "${path.module}/scripts/database/bootstrap.sh",
    {
      project_name       = var.project_name
      environment        = var.environment
      service_name       = local.database
      database_workspace = local.database_workspace
      # ...
    }
  )
}
```

The rendered result is then supplied to the module:

```hcl
module "compute_storage" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute-storage.git?ref=v1.0.0"

  # ...

  user_data = local.database_user_data
}
```

## Persistent EBS storage

Persistent storage is optional.

Enable it with:

```hcl
enable_data_volume_mount = true
```

When enabled, the module creates the EBS volume and attaches it to the EC2 instance.

When disabled, no EBS volume resource is created.

### `data_volume_device`

Linux device name used when attaching the EBS volume.

Default:

```hcl
data_volume_device = "/dev/sdb"
```

This value is passed to the EBS module.

### `enable_data_volume_mount`

Controls whether the independent EBS volume is created and attached.

Default:

```hcl
enable_data_volume_mount = false
```

Example:

```hcl
enable_data_volume_mount = true
```

### `data_volume_mount_path`

This variable is retained for compatibility with caller-owned bootstrap logic.

The compute-storage module itself does not mount the filesystem inside the operating system. The caller's `user_data` implementation is responsible for formatting and mounting the device when required.

For example:

```hcl
data_volume_mount_path = "/opt/mavis/database"
```

## Storage lifecycle

The EBS volume is conditionally created using:

```hcl
count = var.enable_data_volume_mount ? 1 : 0
```

Therefore:

```hcl
enable_data_volume_mount = false
```

creates:

```text
EC2
└── Root volume
```

while:

```hcl
enable_data_volume_mount = true
```

creates:

```text
EC2
├── Root volume
└── Persistent EBS volume
```

The EBS volume is managed independently from the EC2 root volume through the reusable EBS module.

## Outputs

### `instance_id`

ID of the EC2 instance.

```hcl
module.compute_storage.instance_id
```

### `private_ip`

Private IP address of the EC2 instance.

```hcl
module.compute_storage.private_ip
```

### `availability_zone`

Availability Zone containing the EC2 instance.

```hcl
module.compute_storage.availability_zone
```

### `data_volume_id`

ID of the optional persistent EBS volume.

When storage is disabled, the output is:

```text
null
```

Example:

```hcl
module.compute_storage.data_volume_id
```

## Example

```hcl
module "compute_storage" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute-storage.git?ref=v1.0.0"

  project_name = var.project_name
  environment  = var.environment
  service_name = "database"

  subnet_id         = module.vpc_base.isolated_subnet_ids[0]
  security_group_id = module.internal_sg.security_group_id

  instance_type    = "t3.medium"
  root_volume_size = 20

  enable_route53_write_access = true
  hosted_zone_id              = module.dns_acm.private_zone_id

  enable_ecr_read_access = true

  enable_data_volume_mount = true
  data_volume_device       = "/dev/sdb"

  user_data = local.database_user_data
}
```

## Service-specific bootstrap

Because `user_data` is caller-owned, service-specific implementation can remain outside this module.

A database workload could provide:

```text
scripts/
└── database/
    ├── bootstrap.sh
    ├── bootstrap.py
    ├── update.sh
    ├── provision.sh
    └── .env
```

The caller renders the bootstrap script and supplies it to this module.

This keeps the compute-storage module generic and prevents database-specific implementation from becoming part of the reusable compute/storage abstraction.

## Module composition

The module internally consumes:

```text
terraform-aws-compute
        +
terraform-aws-ebs
        =
terraform-aws-compute-storage
```

The compute module remains independently reusable for workloads that do not require persistent secondary storage.

The EBS module remains independently reusable for workloads that need separately managed persistent storage.

This module provides the convenient composition when both are required.

## Validation

Before committing changes, run:

```powershell
terraform fmt -recursive
terraform init
terraform validate
```

For an example configuration:

```powershell
cd examples/complete
terraform init
terraform validate
```

If the module has already been initialized and dependency versions need to be refreshed:

```powershell
terraform init -upgrade
```

## Recommended repository structure

```text
terraform-aws-compute-storage/
├── .gitignore
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── examples/
│   └── complete/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── .terraform.lock.hcl
```

The `.terraform/` directory and Terraform state files should not be committed.

## Requirements

The module expects compatible versions of:

* Terraform
* HashiCorp AWS provider
* `terraform-aws-compute`
* `terraform-aws-ebs`

The exact provider constraint should be defined in `versions.tf`.

## Design principles

This module follows a few important boundaries:

1. Compute configuration is delegated to the reusable compute module.
2. Persistent secondary storage is delegated to the reusable EBS module.
3. Application-specific bootstrap logic remains caller-owned.
4. Route 53 permissions are exposed as configurable compute capabilities.
5. ECR permissions are exposed as configurable compute capabilities.
6. Secondary storage is optional.
7. The EC2 instance and persistent EBS volume remain separate resources.
8. The module does not assume that every workload needs persistent storage.

This makes the module suitable for database hosts, stateful services, application servers, and other workloads requiring EC2 compute with optional independent persistent storage.
