# terraform-google-cloud-build-slack-notifier

A Terraform module to enable Slack notifications for Cloud Build events.

**Note - This will add the following resources to your project:**

- Google Secret Manager for storing the Slack Webhook URL
- Google Cloud Storage Bucket for storing the notifier configuration
- Google Pub/Sub for events emitted from Cloud Build
- Google Cloud Run for processing the events emitted from Cloud Build

This module is mostly based on instructions found in GCP's [Configuring Slack notifications](https://cloud.google.com/build/docs/configuring-notifications/configure-slack).

## Setup

You will need a Slack app incoming webhook url for this to work.

- Create a [Slack app](https://api.slack.com/apps?new_app=1) for your desired Slack workspace.
- Activate [incoming webhooks](https://api.slack.com/messaging/webhooks) to post messages from Cloud Build to Slack.
- After this module has run, add the webhook url to the secret in the UI

## Pre-commit Hooks

[Pre-commit](https://pre-commit.com/) hooks have been configured for this repo.

The enabled hooks check for a variety of common problems in Terraform code, and
will run any time you commit to your branch.

Pre-commit (and dependencies) can be installed by running:
`brew install pre-commit coreutils terraform-docs`

To enable the hooks locally, run the following from the root of this repo:
`pre-commit install`

To uninstall the hooks, run the following from the root of this repo:
`pre-commit uninstall`

To skip running the hooks when you commit:
`git commit -n` aka `git commit --no-verify`

**Currently enabled plugins:**

- [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
  - `terraform_fmt`: Rewrites all Terraform configuration files to a canonical format
  - `terraform_docs`: Inserts input and output documentation into `README.md`
  - `terraform_validate`: Validates all Terraform configuration files
- [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks)
  - `end-of-file-fixer`: Makes sure files end in a newline and only a newline
  - `trailing-whitespace`: Trims trailing whitespace
  - `check-merge-conflict`: Check for files that contain merge conflict strings

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_cloudfunctions_function.slack_notifier](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_cloudfunctions_function) | resource |
| [google_project_service.apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_pubsub_topic.cloud_builds](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_secret_manager_secret.cloud_build_slack_webhook_url](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.slack_notifier_secret_accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account.slack_notifier](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.cloud_build_notifier](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_object.cloud_build_slack_notifier_script](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [random_id.cloud_build_notifier](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [archive_file.slack_notifier](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_cloud_build_event_filter"></a> [cloud\_build\_event\_filter](#input\_cloud\_build\_event\_filter) | The filter to apply to incoming Cloud Build events. | `string` | `"build.substitutions[\"BRANCH_NAME\"] == \"main\""` |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID for the project in which Cloud Build is running. | `string` | n/a |
| <a name="input_slack_channel_name"></a> [slack\_channel\_name](#input\_slack\_channel\_name) | The Slack channel name in which to publish notifications. | `string` | n/a |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
