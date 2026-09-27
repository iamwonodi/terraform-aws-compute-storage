# Plans the module against a mocked AWS provider. Run with "terraform test"
# (or "tofu test") from the repository root.

mock_provider "aws" {}

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
