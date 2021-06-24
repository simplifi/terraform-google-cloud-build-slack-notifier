variable "project_id" {
  description = "Project ID for the project in which Cloud Build is running."
  type        = string
}

variable "name" {
  description = "The name to use on all resources created. A good name might be the name of the Slack channel in which this notifier will publish messages."
  type        = string
}

variable "slack_webhook_url_secret_id" {
  description = "The GSM secret for the existing Slack webhook URL. Optional - If not provided a secret will be created with the value of 'slack_webhook_url'."
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "The Slack webhook URL on which to publish notifications. Optional - If not provided it the existing secret_id should be passed in on 'slack_webhook_url_secret_id'."
  type        = string
  sensitive   = true
  default     = ""
}

# See: https://cloud.google.com/build/docs/configuring-notifications/configure-slack#using_cel_to_filter_build_events
variable "cloud_build_event_filter" {
  description = "The filter to apply to incoming Cloud Build events."
  type        = string
  default     = "build.substitutions[\"BRANCH_NAME\"] == \"main\""
}

