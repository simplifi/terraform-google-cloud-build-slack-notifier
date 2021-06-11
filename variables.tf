variable "project_id" {
  description = "Project ID for the project in which Cloud Build is running."
  type        = string
}

variable "slack_channel_name" {
  description = "The Slack channel name in which to publish notifications."
  type        = string
}

# See: https://cloud.google.com/build/docs/configuring-notifications/configure-slack#using_cel_to_filter_build_events
variable "cloud_build_event_filter" {
  description = "The filter to apply to incoming Cloud Build events."
  type        = string
  default     = "build.substitutions[\"BRANCH_NAME\"] == \"main\""
}
