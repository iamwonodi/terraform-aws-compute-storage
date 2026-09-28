# Terraform AWS Compute Storage Module

A reusable Terraform module for provisioning an EC2 compute instance with optional persistent secondary EBS storage.

The module composes two independently reusable modules:

* `terraform-aws-compute`
* `terraform-aws-ebs`

The purpose of this module is to provide a convenient higher-level abstraction for workloads that require both EC2 compute and separately managed persistent EBS storage.

The module intentionally does **not** manage IAM roles or instance profiles. IAM is treated as an independent infrastructure concern and can be provided by the caller through the `instance_profile_name` input.

---

## Architecture

```text
                         Calling Infrastructure
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                    │
             ▼                    ▼                    ▼
       VPC / Subnets       Security Groups        AWS Profile
                                                     │
                                                     ▼
                                          IAM Instance Profile
                                                     │
                                                     │
                                  ┌──────────────────┘
                                  │
                                  ▼
                      ┌────────────────────────┐
                      │  Compute Storage       │
                      │                        │
                      │  terraform-aws-compute │
                      │           │            │
                      │           ▼            │
                      │      EC2 Instance      │
                      │           │            │
                      │           ▼            │
                      │    terraform-aws-ebs   │
                      │           │            │
                      └───────────┼────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
              EC2 Root Volume          Optional Data Volume
                                           Persistent EBS
```

The caller owns the surrounding infrastructure and supplies the required resource identifiers.

This includes:

* VPC
* Subnet
* Security Group
* IAM Instance Profile
* Optional AMI
* User-data configuration

The compute-storage module composes the compute and storage building blocks without taking ownership of those surrounding concerns.

---

## What This Module Does

The module provides a higher-level composition of:

```text
terraform-aws-compute
        +
terraform-aws-ebs
        =
terraform-aws-compute-storage
```

The underlying compute module is responsible for creating the EC2 instance.

The underlying EBS module is responsible for creating and attaching an optional persistent secondary EBS volume.

This module therefore provides a convenient abstraction for workloads that need:

```text
EC2 Compute
    +
Optional Persistent Storage
```

while keeping both underlying modules independently reusable.

---

## Module Responsibilities

### Compute

The underlying `terraform-aws-compute` module is responsible for:

* EC2 instance creation
* AMI selection
* EC2 instance type
* Subnet placement
* Security group association
* Root EBS volume
* User-data configuration
* Optional IAM instance profile attachment

The compute module does **not** create the IAM instance profile when the caller supplies one.

The caller is responsible for creating the appropriate IAM profile, for example through the independent `terraform-aws-aws-profile` module.

---

### Storage

The underlying `terraform-aws-ebs` module is responsible for:

* Secondary EBS volume creation
* Volume size
* Volume type
* Volume encryption
* Volume attachment
* Persistent volume lifecycle

The secondary volume is created only when:

```hcl
enable_data_volume_mount = true
```

When disabled, the module does not create the secondary EBS volume.

---

# IAM Responsibility

IAM is intentionally outside the responsibility of this module.

The architecture separates IAM from compute:

```text
                    AWS Profile Module
                           │
                           ▼
                    IAM Role
                           │
                           ▼
                 IAM Instance Profile
                           │
                           │
                           ▼
                    Compute Storage
                           │
                           ▼
                       EC2
```

This allows the same IAM profile module to be reused by:

* EC2 instances
* EC2 Image Builder
* other EC2-based workloads

The compute-storage module simply accepts the profile name:

```hcl
instance_profile_name = var.instance_profile_name
```

This prevents the compute-storage abstraction from embedding workload-specific IAM permissions.

For example, IAM capabilities such as:

* Systems Manager
* ECR access
* Route 53 access
* additional managed policies

can be managed by the caller through the independent IAM/profile infrastructure.

---

# AMI Selection

The module supports an optional caller-supplied AMI.

```hcl
ami_id = var.ami_id
```

When an AMI ID is supplied, the compute module uses that AMI.

When:

```hcl
ami_id = null
```

the underlying compute module falls back to its default Ubuntu AMI selection logic.

This provides two usage patterns.

### Use the default Ubuntu AMI

```hcl
ami_id = null
```

### Use a custom AMI

```hcl
ami_id = "ami-0123456789abcdef0"
```

This is particularly useful when the caller has an AMI produced by an independent image-building pipeline such as the `terraform-aws-ubuntu-ami` module.

For example:

```text
Ubuntu AMI Module
       │
       ▼
   Custom AMI
       │
       ▼
Compute Storage
       │
       ▼
     EC2
```

This keeps AMI creation and EC2 provisioning as separate concerns.

When that AMI is built in the same apply as the host, its ID is unknown at plan time. Set `ami_lookup_enabled = false` as well, so Terraform does not need to know whether `ami_id` is null to plan the Ubuntu lookup:

```hcl
ami_id             = module.ubuntu_ami.ami_id
ami_lookup_enabled = false
```

Terraform modules are designed to accept caller-provided values through input variables, which makes this pattern appropriate for reusable module composition.

---

# Usage

A typical caller can provide the compute configuration together with an existing IAM instance profile:

```hcl
module "compute_storage" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute-storage.git?ref=v1.3.1"

  project_name = var.project_name
  environment  = var.environment
  service_name = "database"

  subnet_id         = module.vpc_base.isolated_subnet_ids[0]
  security_group_id = module.internal_sg.security_group_id

  ami_id = var.ami_id

  instance_type = "t3.medium"

  instance_profile_name = module.aws_profile.instance_profile_name

  associate_public_ip_address = false

  root_volume_size = 20

  user_data = local.database_user_data

  enable_data_volume_mount = true

  data_volume_device = "/dev/sdb"
  data_volume_size   = 50
}
```

The caller therefore controls:

```text
Networking
IAM
AMI
Compute configuration
Bootstrap
Storage configuration
```

while this module handles the composition of compute and persistent storage.

---

# Compute Configuration

## `project_name`

Name of the project consuming the module.

```hcl
project_name = "mavis"
```

---

## `environment`

Deployment environment.

```hcl
environment = "development"
```

---

## `service_name`

Logical name of the workload.

```hcl
service_name = "database"
```

The combination of project, environment, and service identifies the workload.

---

## `subnet_id`

Subnet where the EC2 instance is deployed.

```hcl
subnet_id = module.vpc_base.isolated_subnet_ids[0]
```

The subnet is owned by the calling infrastructure.

The compute-storage module does not create the subnet.

---

## `security_group_id`

Security group attached to the EC2 instance.

```hcl
security_group_id = module.internal_sg.security_group_id
```

The security group is owned by the calling infrastructure.

---

## `ami_id`

Optional AMI ID.

```hcl
ami_id = null
```

When `null`, the underlying compute module uses its default Ubuntu AMI selection.

A custom AMI can be supplied:

```hcl
ami_id = var.ubuntu_ami_id
```

This is useful when the AMI has been created by an independent image-building workflow.

---

## `ami_lookup_enabled`

Optional. Whether the underlying compute module looks up the latest Ubuntu AMI.

```hcl
ami_lookup_enabled = null
```

When `null`, the lookup runs only when `ami_id` is null. Set `false` when `ami_id` is known only after apply, such as an AMI built in the same apply; without it the plan stops with "Invalid count argument".

---

## `instance_type`

EC2 instance type.

Default:

```hcl
instance_type = "t3.medium"
```

Example:

```hcl
instance_type = "t3.large"
```

---

## `instance_profile_name`

Optional IAM instance profile to attach to the EC2 instance.

Default:

```hcl
instance_profile_name = null
```

Example:

```hcl
instance_profile_name = module.aws_profile.instance_profile_name
```

The profile is not created by this module.

This allows the caller to independently control IAM permissions.

For example:

```text
AWS Profile Module
       │
       ▼
IAM Instance Profile
       │
       ▼
Compute Storage
       │
       ▼
EC2
```

If no profile is required:

```hcl
instance_profile_name = null
```

The EC2 instance is created without an IAM instance profile.

---

## `associate_public_ip_address`

Controls whether the EC2 instance receives a public IPv4 address.

Default:

```hcl
associate_public_ip_address = false
```

For most internal workloads, keeping this disabled is recommended.

---

## `root_volume_size`

Size of the EC2 root EBS volume in GiB.

Default:

```hcl
root_volume_size = 15
```

Example:

```hcl
root_volume_size = 30
```

The root volume is managed by the underlying compute module.

---

## `user_data`

Caller-provided EC2 user-data configuration.

```hcl
user_data = local.database_user_data
```

The compute-storage module does not contain application-specific bootstrap logic.

This allows the caller to control:

* operating-system configuration
* Docker installation
* application deployment
* database configuration
* service configuration
* storage formatting
* storage mounting
* secrets integration
* application-specific initialization

For example:

```hcl
locals {
  database_user_data = templatefile(
    "${path.module}/scripts/database/bootstrap.sh",
    {
      project_name = var.project_name
      environment  = var.environment
      service_name = var.service_name
    }
  )
}
```

The rendered value is then supplied to the module:

```hcl
user_data = local.database_user_data
```

Supply the script as plain text. The module base64-encodes it for EC2.

User data runs only at first boot. When the host is rebuilt from its script, set `user_data_replace_on_change = true` so a changed script replaces the instance instead of being stored and never run. The data volume is a separate resource, so it is kept and reattached to the new instance:

```hcl
user_data                   = local.database_user_data
user_data_replace_on_change = true
```

---

# Persistent EBS Storage

Persistent secondary storage is optional.

Enable it with:

```hcl
enable_data_volume_mount = true
```

When enabled:

```text
EC2
├── Root EBS Volume
└── Secondary Persistent EBS Volume
```

When disabled:

```text
EC2
└── Root EBS Volume
```

The secondary volume is independently managed through the reusable `terraform-aws-ebs` module.

---

## `enable_data_volume_mount`

Controls whether the secondary EBS volume is created.

Default:

```hcl
enable_data_volume_mount = false
```

Enable:

```hcl
enable_data_volume_mount = true
```

The resource is conditionally created using:

```hcl
count = var.enable_data_volume_mount ? 1 : 0
```

---

## `data_volume_device`

Linux device name used when attaching the secondary EBS volume.

Default:

```hcl
data_volume_device = "/dev/sdb"
```

Example:

```hcl
data_volume_device = "/dev/sdf"
```

The value is passed to the underlying EBS module.

---

## `data_volume_size`

Size of the secondary EBS volume in GiB.

Default:

```hcl
data_volume_size = 50
```

Example:

```hcl
data_volume_size = 100
```

The secondary volume is independent of the EC2 root volume.

---

# Storage Lifecycle

The secondary EBS volume is conditionally created.

When:

```hcl
enable_data_volume_mount = false
```

the module creates:

```text
EC2
└── Root Volume
```

When:

```hcl
enable_data_volume_mount = true
```

the module creates:

```text
EC2
├── Root Volume
└── Persistent EBS Volume
```

The secondary EBS volume is managed through the independent EBS module.

This separation allows persistent data storage to remain conceptually separate from the lifecycle of the EC2 root volume.

---

# Storage Mounting

This module creates and attaches the EBS volume.

It does **not** format or mount the filesystem inside the operating system.

The caller's `user_data` is responsible for operating-system-level configuration such as:

```text
Partitioning
     │
     ▼
Formatting
     │
     ▼
Mounting
     │
     ▼
Application directory
```

For example, the caller may use its bootstrap script to mount:

```text
/dev/sdb
    │
    ▼
/opt/mavis/database
```

This keeps operating-system and application-specific behavior outside the reusable compute-storage abstraction.

---

# Module Composition

Internally, the module consumes:

```text
terraform-aws-compute
        │
        │
        ▼
     EC2 Instance
        │
        │
        ▼
terraform-aws-ebs
        │
        ▼
Secondary EBS Volume
```

Therefore:

```text
terraform-aws-compute
        +
terraform-aws-ebs
        =
terraform-aws-compute-storage
```

The individual modules remain independently reusable.

### `terraform-aws-compute`

Useful when a workload requires EC2 compute but does not require the higher-level storage composition.

### `terraform-aws-ebs`

Useful when persistent EBS storage needs to be managed independently.

### `terraform-aws-compute-storage`

Useful when a workload requires both.

---

# What This Module Does Not Create

The module intentionally does not create:

* VPC
* Subnets
* Route Tables
* Internet Gateway
* NAT Gateway
* Security Groups
* Application Load Balancers
* Target Groups
* Route 53 Hosted Zones
* ACM Certificates
* ECR Repositories
* IAM Roles
* IAM Instance Profiles

These resources belong to the surrounding infrastructure.

The caller supplies the resources or values required by this module.

---

# IAM Separation

IAM is intentionally separated from the compute-storage module.

For example:

```text
                         Core Infrastructure
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                    │
             ▼                    ▼                    ▼
          Network              AWS Profile          AMI
             │                    │                    │
             │                    ▼                    │
             │             IAM Instance Profile       │
             │                    │                    │
             └────────────────────┼────────────────────┘
                                  │
                                  ▼
                       Compute Storage Module
                                  │
                                  ▼
                             EC2 Instance
                                  │
                                  ▼
                         Optional EBS Volume
```

This provides a clean separation of responsibilities:

```text
AWS Profile
    └── IAM

Compute
    └── EC2

EBS
    └── Persistent Storage

Compute Storage
    └── Composition
```

The caller can therefore create a profile with exactly the permissions required by the workload and pass only its name into the compute layer.

---

# Example with AWS Profile

A core infrastructure configuration can compose the modules as follows:

```hcl
module "aws_profile" {
  source = "git::https://github.com/iamwonodi/terraform-aws-aws-profile.git?ref=v1.0.0"

  project_name = var.project_name
  environment  = var.environment
  service_name = var.service_name

  enable_ssm_access      = true
  enable_ecr_read_access = true
}
```

Then:

```hcl
module "compute_storage" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute-storage.git?ref=v1.3.1"

  project_name = var.project_name
  environment  = var.environment
  service_name = var.service_name

  subnet_id         = module.vpc_base.isolated_subnet_ids[0]
  security_group_id = module.internal_sg.security_group_id

  instance_profile_name = module.aws_profile.instance_profile_name

  ami_id = var.ami_id

  instance_type = "t3.medium"

  root_volume_size = 20

  enable_data_volume_mount = true
  data_volume_device        = "/dev/sdb"
  data_volume_size          = 50

  user_data = local.database_user_data
}
```

This is the preferred composition because the compute-storage module does not need to know which IAM policies are required by the workload.

Terraform modules communicate through inputs and outputs, making this kind of composition a natural module boundary.

---

# Example with a Custom Ubuntu AMI

When the caller has an independently built AMI:

```hcl
module "ubuntu_ami" {
  source = "git::https://github.com/iamwonodi/terraform-aws-ubuntu-ami.git?ref=v1.1.0"

  project_name = var.project_name
  environment  = var.environment

  parent_image = var.ubuntu_parent_image

  enable_predefined_packages = true
  enable_docker              = true
  enable_aws_cli             = true
  enable_python              = true

  build_image = false
}
```

The resulting AMI can then be supplied to compute-storage:

```hcl
module "compute_storage" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute-storage.git?ref=v1.3.1"

  project_name = var.project_name
  environment  = var.environment
  service_name = "database"

  subnet_id         = module.vpc_base.isolated_subnet_ids[0]
  security_group_id = module.internal_sg.security_group_id

  ami_id = module.ubuntu_ami.ami_id

  instance_profile_name = module.aws_profile.instance_profile_name

  instance_type = "t3.medium"

  enable_data_volume_mount = true

  user_data = local.database_user_data
}
```

This creates a clean pipeline:

```text
Ubuntu AMI Module
       │
       ▼
   Custom AMI
       │
       ▼
Compute Storage
       │
       ▼
      EC2
```

Terraform's module source syntax also supports Git tags through the `ref` query parameter, making versioned module consumption appropriate for this repository structure.

---

# Outputs

## `instance_id`

ID of the EC2 instance.

```hcl
module.compute_storage.instance_id
```

---

## `private_ip`

Private IPv4 address of the EC2 instance.

```hcl
module.compute_storage.private_ip
```

---

## `availability_zone`

Availability Zone containing the EC2 instance.

```hcl
module.compute_storage.availability_zone
```

---

## `data_volume_id`

ID of the secondary persistent EBS volume.

When secondary storage is disabled:

```text
null
```

Example:

```hcl
module.compute_storage.data_volume_id
```

---

# Example

A complete configuration may look like:

```hcl
module "compute_storage" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute-storage.git?ref=v1.3.1"

  project_name = var.project_name
  environment  = var.environment
  service_name = "database"

  subnet_id         = module.vpc_base.isolated_subnet_ids[0]
  security_group_id = module.internal_sg.security_group_id

  ami_id = var.ami_id

  instance_type = "t3.medium"

  instance_profile_name = module.aws_profile.instance_profile_name

  associate_public_ip_address = false

  root_volume_size = 20

  enable_data_volume_mount = true

  data_volume_device = "/dev/sdb"
  data_volume_size   = 50

  user_data = local.database_user_data
}
```

---

# Service-Specific Bootstrap

Because `user_data` is caller-owned, service-specific implementation remains outside this module.

For example:

```text
scripts/
└── database/
    ├── bootstrap.sh
    ├── bootstrap.py
    ├── update.sh
    ├── provision.sh
    └── .env
```

The caller renders the required bootstrap configuration and passes the resulting user-data to the module.

This prevents database-specific implementation from becoming part of the reusable compute-storage abstraction.

---

# Recommended Repository Structure

```text
terraform-aws-compute-storage/
│
├── .gitignore
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
│
├── examples/
│   └── complete/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── .terraform.lock.hcl
```

The following should not be committed:

```text
.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
*.tfvars
*.tfvars.json
```

---

# Validation

Before committing changes, run:

```powershell
terraform fmt -recursive

terraform init

terraform validate
```

For the complete example:

```powershell
cd examples/complete

terraform init

terraform validate
```

If module dependencies have changed and need to be refreshed:

```powershell
terraform init -upgrade
```

Terraform requires `terraform init` when module sources change or when modules need to be upgraded.

---

# Requirements

The module expects compatible versions of:

* Terraform
* HashiCorp AWS provider
* `terraform-aws-compute`
* `terraform-aws-ebs`

The exact Terraform and provider constraints should be defined in `versions.tf`.

The caller must also have permission to create and manage the AWS resources required by the underlying modules.

---

# Design Principles

This module follows several important boundaries.

1. **Compute is delegated to `terraform-aws-compute`.**

2. **Persistent secondary storage is delegated to `terraform-aws-ebs`.**

3. **IAM is delegated to an independently managed profile module or caller-owned IAM resources.**

4. **AMI creation is independent from EC2 provisioning.**

5. **The caller may supply a custom AMI through `ami_id`.**

6. **When `ami_id` is `null`, the compute module can use its default Ubuntu AMI selection.**

7. **Application-specific bootstrap logic remains caller-owned.**

8. **Secondary storage is optional.**

9. **The secondary EBS volume has an independent lifecycle from the EC2 root volume.**

10. **Networking remains caller-owned.**

11. **The module does not assume that every workload requires persistent storage.**

12. **The module does not embed workload-specific IAM permissions.**

These boundaries keep the module small, predictable, composable, and reusable.

---

# Example Core Infrastructure Architecture

```text
                           CORE INFRASTRUCTURE
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
   VPC / Subnets             AWS Profile              Ubuntu AMI
        │                         │                         │
        │                         ▼                         │
        │                  IAM Instance Profile             │
        │                         │                         │
        └─────────────────────────┼─────────────────────────┘
                                  │
                                  ▼
                    terraform-aws-compute-storage
                                  │
                         ┌────────┴────────┐
                         │                 │
                         ▼                 ▼
                    EC2 Instance     Persistent EBS
                         │                 │
                         │                 │
                         ▼                 ▼
                    Root Volume       Data Volume
```

The resulting architecture separates the major infrastructure concerns:

```text
IAM          → aws-profile
AMI          → ubuntu-ami
Compute      → compute
Persistent   → ebs
Composition  → compute-storage
Networking   → vpc / security-group modules
Application  → caller-owned user-data
```

This is the intended role of `terraform-aws-compute-storage`: **compose independently reusable infrastructure modules without taking ownership of responsibilities that belong elsewhere.**

---

# Testing

```powershell
terraform fmt -recursive
terraform init
terraform validate
terraform test
```

`terraform test` plans the module against a mocked AWS provider (no credentials needed) with an AMI ID that is unknown until apply.

---

# Releases

* `v1.3.1` takes the data volume's availability zone from the host's subnet instead of from the instance. A replacement instance's zone is unknown until it exists, and a volume cannot change zone, so every host replacement also planned to replace, and so empty, the data volume. The subnet already exists and never moves, so replacing the host now keeps the volume and reattaches it. Inputs and outputs are unchanged. The module now reads the subnet (`ec2:DescribeSubnets`).
* `v1.3.0` uses `terraform-aws-compute` v1.3.0 and passes its new optional `user_data_replace_on_change` input through (default `false`, so existing hosts are unaffected).
* `v1.2.1` base64-encodes `user_data` before passing it to `terraform-aws-compute`, which expects it encoded. Earlier releases passed the plain-text script through unchanged, so a plan stopped with "user_data_base64 ... must be base64-encoded" as soon as the script was fully known. Callers keep passing plain text.
* `v1.2.0` uses `terraform-aws-compute` v1.2.0 and passes its new optional `ami_lookup_enabled` input through. Left null, the module behaves as `v1.1.0`.
* `v1.1.0` caller-supplied AMI.
