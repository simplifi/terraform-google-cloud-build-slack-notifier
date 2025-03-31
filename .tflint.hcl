# Basic Terraform rules
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/README.md
plugin "terraform" {
  enabled = true
}

#	Disallow specifying a git or mercurial repository as a module source without pinning to a version
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_module_pinned_source.md
rule "terraform_module_pinned_source" {
  enabled = true
}

# Checks that Terraform modules sourced from a registry specify a version
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_module_version.md
rule "terraform_module_version" {
  enabled = true
}

# Require that all providers have version constraints through required_providers
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_required_providers.md
rule "terraform_required_providers" {
  enabled = true
}

# Ensure that a module complies with the Terraform Standard Module Structure
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/terraform_standard_module_structure.md
# The above link to docs is a bit misleading as this does not actully check for
# Terraform Standard Module Structure.
# This actually checks that each module has main.tf, variables.tf, output.tf,
# and that variables/outputs are not included in main.tf.
rule "terraform_standard_module_structure" {
  enabled = true
}
