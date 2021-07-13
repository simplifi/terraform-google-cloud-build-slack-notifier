# terraform-google-cloud-build-slack-notifier

[![Build Status](https://www.travis-ci.com/simplifi/terraform-google-cloud-build-slack-notifier.svg?token=Tyt37RU5xWf1sPRSJyoD&branch=main)](https://www.travis-ci.com/simplifi/terraform-google-cloud-build-slack-notifier)

A Terraform module to enable Slack notifications for Cloud Build events.

**Note - This will add the following resources to your project:**

- Google Cloud Storage Bucket for storing the notifier configuration
- Google Pub/Sub for events emitted from Cloud Build
- Google Cloud Run for processing the events emitted from Cloud Build

This module is based on the instructions found in GCP's [Configuring Slack notifications](https://cloud.google.com/build/docs/configuring-notifications/configure-slack) guide.

## Setup

You will need a Slack app incoming webhook url stored in a Google Secret Manager
secret for this to work.

- Create a [Slack app](https://api.slack.com/apps?new_app=1) for your desired Slack workspace.
- Activate [incoming webhooks](https://api.slack.com/messaging/webhooks) to post messages from Cloud Build to Slack.
- Create a new secret in Google Secret Manager and store the webhook url in it.

## Pre-commit Hooks

[Pre-commit](https://pre-commit.com/) hooks have been configured for this repo.

The enabled hooks check for a variety of common problems in Terraform code, and
will run any time you commit to your branch.

Pre-commit (and dependencies) can be installed by following the instructions
found here:

- [Install `pre-commit`](https://pre-commit.com/#install)
- [Install `terraform-docs`](https://github.com/terraform-docs/terraform-docs#installation)

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

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 3.74 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | ~> 3.74 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 3.74 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | ~> 3.74 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_cloud_run_service.cloud_build_notifier](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_cloud_run_service) | resource |
| [google-beta_google_project_service_identity.pubsub](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_project_service_identity) | resource |
| [google_project_iam_member.notifier_project_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.pubsub_invoker_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.pubsub_project_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_pubsub_subscription.cloud_builds](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_topic.cloud_builds](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_secret_manager_secret_iam_member.notifier_secret_accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account.notifier](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.pubsub_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.cloud_build_notifier](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_object.cloud_build_notifier_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [random_id.cloud_build_notifier](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.cloud_build_notifier_service](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [google_project.slack_webhook_url_secret_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_secret_manager_secret_version.slack_webhook_url](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_cloud_build_event_filter"></a> [cloud\_build\_event\_filter](#input\_cloud\_build\_event\_filter) | The CEL filter to apply to incoming Cloud Build events. | `string` | `"build.substitutions['BRANCH_NAME'] == 'main' && build.status in [Build.Status.SUCCESS, Build.Status.FAILURE, Build.Status.TIMEOUT]"` |
| <a name="input_cloud_build_notifier_image"></a> [cloud\_build\_notifier\_image](#input\_cloud\_build\_notifier\_image) | The image to use for the notifier. | `string` | `"us-east1-docker.pkg.dev/gcb-release/cloud-build-notifiers/slack:latest"` |
| <a name="input_name"></a> [name](#input\_name) | The name to use on all resources created. | `string` | n/a |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID of the project in which Cloud Build is running. | `string` | n/a |
| <a name="input_region"></a> [region](#input\_region) | The region in which to deploy the notifier service. | `string` | `"us-central1"` |
| <a name="input_slack_webhook_url_secret_id"></a> [slack\_webhook\_url\_secret\_id](#input\_slack\_webhook\_url\_secret\_id) | The ID of an existing Google Secret Manager secret, containing a Slack webhook URL. | `string` | n/a |
| <a name="input_slack_webhook_url_secret_project"></a> [slack\_webhook\_url\_secret\_project](#input\_slack\_webhook\_url\_secret\_project) | The project ID containing the slack\_webhook\_url\_secret\_id. | `string` | n/a |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
