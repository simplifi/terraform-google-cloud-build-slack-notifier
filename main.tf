# Cloud Build Slack Notifier

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    # Ensure cloudbuild API is enabled (it should already be though)
    "cloudbuild.googleapis.com",
    # Cloud Functions is running our notifier
    "cloudfunctions.googleapis.com",
    # Pub/Sub is used to handle events from Cloud Build
    "pubsub.googleapis.com",
    # Slack webhook URL is stored in GSM for Cloud Run to use
    "secretmanager.googleapis.com"
  ])
  project = var.project_id
  service = each.key

  disable_dependent_services = true
}


# ------------------------------------------------------------------------------
# Service Accounts
# ------------------------------------------------------------------------------

# Create the slack_notifier service account
resource "google_service_account" "slack_notifier" {
  account_id = "slack-notifier"
  project    = var.project_id
}


# ------------------------------------------------------------------------------
# Secrets
# ------------------------------------------------------------------------------

# Setup a secret to store incoming slack webhook URL in Secret Manager
resource "google_secret_manager_secret" "cloud_build_slack_webhook_url" {
  project   = var.project_id
  secret_id = "cloud-build-slack-webhook-url-${var.slack_channel_name}"

  replication {
    automatic = true
  }
}

# Give the slack notifier service account access to the secret
resource "google_secret_manager_secret_iam_member" "slack_notifier_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.cloud_build_slack_webhook_url.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.slack_notifier.email}"
}


# ------------------------------------------------------------------------------
# Pub/Sub
# ------------------------------------------------------------------------------

# Create the cloud-builds topic to receive build update messages for your notifier
resource "google_pubsub_topic" "cloud_builds" {
  project = var.project_id
  name    = "cloud-builds"
}


# ------------------------------------------------------------------------------
# GCS Bucket
# ------------------------------------------------------------------------------

# Create bucket
resource "random_id" "cloud_build_notifier" {
  byte_length = 4
}

resource "google_storage_bucket" "cloud_build_notifier" {
  project       = var.project_id
  name          = "${var.project_id}-us-cloud-build-notifier-${random_id.cloud_build_notifier.hex}"
  force_destroy = true
}

data "archive_file" "slack_notifier" {
  type        = "zip"
  source_dir  = "${path.module}/slack_notifier"
  output_path = "${path.module}/slack_notifier.zip"
}

resource "google_storage_bucket_object" "cloud_build_slack_notifier_script" {
  name   = "slack_notifier.zip"
  source = data.archive_file.slack_notifier.output_path
  bucket = google_storage_bucket.cloud_build_notifier.name
}


# ------------------------------------------------------------------------------
# Cloud Function
# ------------------------------------------------------------------------------
resource "google_cloudfunctions_function" "slack_notifier" {
  provider    = google-beta
  name        = "slack-notifier-${regex("[0-9A-Za-z]+", google_storage_bucket_object.cloud_build_slack_notifier_script.crc32c)}" # HACK To make the function change when the script changes
  description = "Slack Notifier"
  runtime     = "python39"
  project     = var.project_id
  region      = "us-central1" # Note: This can only be us-central1 according to docs

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.cloud_build_notifier.name
  source_archive_object = google_storage_bucket_object.cloud_build_slack_notifier_script.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "cloud-builds"
  }

  timeout     = 60
  entry_point = "handle_cloudbuild_event"

  environment_variables = {
    SECRET_ID = google_secret_manager_secret.cloud_build_slack_webhook_url.id
  }

  service_account_email = google_service_account.slack_notifier.email

  depends_on = [
    google_storage_bucket_object.cloud_build_slack_notifier_script
  ]
}
