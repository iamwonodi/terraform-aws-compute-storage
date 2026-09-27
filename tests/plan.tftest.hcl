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
