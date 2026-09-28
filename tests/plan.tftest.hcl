# Plans the module against a mocked AWS provider. Run with "terraform test"
# (or "tofu test") from the repository root.

mock_provider "aws" {
  mock_data "aws_subnet" {
    defaults = {
      availability_zone = "af-south-1a"
    }
  }
}

run "ami_id_unknown_until_apply" {
  command = plan

  module {
    source = "./tests/unknown_ami"
  }

  variables {
    ami_lookup_enabled = false
  }
}

# The caller passes the rendered script as plain text; EC2 needs it
# base64-encoded. v1.2.0 passed it through unchanged, and the provider refused
# the plan ("user_data_base64 ... must be base64-encoded").
run "plain_text_user_data" {
  command = plan

  module {
    source = "./tests/unknown_ami"
  }

  variables {
    ami_lookup_enabled = false
    user_data          = "#!/usr/bin/env bash\nset -euo pipefail\necho \"database host bootstrap\"\n"
  }
}

run "user_data_replace_on_change" {
  command = plan

  module {
    source = "./tests/unknown_ami"
  }

  variables {
    ami_lookup_enabled          = false
    user_data                   = "#!/usr/bin/env bash\necho \"database host bootstrap\"\n"
    user_data_replace_on_change = true
  }
}

# The data volume's zone comes from the subnet, known at plan time, not from
# the instance: a replacement instance's zone is unknown until it exists, and
# v1.3.0 therefore planned to replace the data volume with every host rebuild.
run "data_volume_zone_comes_from_the_subnet" {
  command = plan

  variables {
    project_name             = "example"
    environment              = "development"
    service_name             = "database"
    subnet_id                = "subnet-0123456789abcdef0"
    security_group_id        = "sg-0123456789abcdef0"
    instance_type            = "t3.medium"
    instance_profile_name    = "example-development-database-profile"
    ami_id                   = "ami-0123456789abcdef0"
    enable_data_volume_mount = true
  }

  assert {
    condition     = data.aws_subnet.host.availability_zone == "af-south-1a"
    error_message = "The data volume's zone should come from the host's subnet."
  }
}
