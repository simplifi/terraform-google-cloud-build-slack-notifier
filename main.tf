# Cloud Build Notifier

locals {
  base_name = "cbn-${var.name}"
}


# ------------------------------------------------------------------------------
# Project
# ------------------------------------------------------------------------------

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    # Ensure cloudbuild API is enabled (it should already be though)
    "cloudbuild.googleapis.com",
    # Compute is used by Cloud Run, which in turn runs the notifier
    "compute.googleapis.com",
    # Pub/Sub is used to handle events from Cloud Build
    "pubsub.googleapis.com",
    # Cloud Run is used to run the notifier
    "run.googleapis.com",
  ])
  project = var.project_id
  service = each.key

  disable_dependent_services = true
}

# ------------------------------------------------------------------------------
# Secrets
# ------------------------------------------------------------------------------

data "google_secret_manager_secret_version" "slack_webhook_url" {
  project = var.slack_webhook_url_secret_project
  secret  = var.slack_webhook_url_secret_id
}


# ------------------------------------------------------------------------------
# Service Accounts
# ------------------------------------------------------------------------------

# Create cloud build notifier service account
resource "google_service_account" "notifier" {
  account_id = "${local.base_name}-nfy"
  project    = var.project_id
}

# Give the service account required project permissions
resource "google_project_iam_member" "notifier_project_roles" {
  for_each = toset([
    "roles/storage.objectViewer",
    "roles/iam.serviceAccountTokenCreator",
    "roles/logging.logWriter"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.notifier.email}"
}

# Give the notifier service account access to the secret
resource "google_secret_manager_secret_iam_member" "notifier_secret_accessor" {
  project   = var.slack_webhook_url_secret_project
  secret_id = var.slack_webhook_url_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.notifier.email}"
}

# Look up the pubsub SA
resource "google_project_service_identity" "pubsub" {
  provider = google-beta
  project  = var.project_id
  service  = "pubsub.googleapis.com"
}

# Grant the Pub/Sub SA permission to create auth tokens in your project
resource "google_project_iam_member" "pubsub_project_roles" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_project_service_identity.pubsub.email}"
}

# Create a pub/sub invoker service account
resource "google_service_account" "pubsub_invoker" {
  account_id = "${local.base_name}-pbs"
  project    = var.project_id
}

# Give the pub/sub invoker service account the Cloud Run Invoker permission
resource "google_project_iam_member" "pubsub_invoker_roles" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.pubsub_invoker.email}"
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
  name          = "${local.base_name}-${random_id.cloud_build_notifier.hex}"
  force_destroy = true
  location      = var.region
}

resource "google_storage_bucket_object" "cloud_build_notifier_config" {
  name   = "${local.base_name}-config.yaml"
  bucket = google_storage_bucket.cloud_build_notifier.name

  content = jsonencode({
    apiVersion = "cloud-build-notifiers/v1"
    kind       = "SlackNotifier"
    metadata = {
      name = local.base_name
    }
    spec = {
      notification = {
        filter = var.cloud_build_event_filter
        delivery = {
          webhookUrl = {
            secretRef = "webhook-url"
          }
        }
      }
      secrets = [
        {
          name  = "webhook-url"
          value = data.google_secret_manager_secret_version.slack_webhook_url.name
        }
      ]
    }
  })
}


# ------------------------------------------------------------------------------
# Cloud Run
# ------------------------------------------------------------------------------

resource "random_id" "cloud_build_notifier_service" {
  # We use a keeper here so we can force cloud run to redeploy on script change.
  keepers = {
    script_hash = google_storage_bucket_object.cloud_build_notifier_config.md5hash
  }

  byte_length = 4
}

resource "google_cloud_run_service" "cloud_build_notifier" {
  provider = google-beta
  name     = "${local.base_name}-${random_id.cloud_build_notifier_service.hex}"
  location = var.region
  project  = var.project_id

  template {
    spec {
      service_account_name = google_service_account.notifier.email

      containers {
        image = var.cloud_build_notifier_image

        env {
          name  = "CONFIG_PATH"
          value = "${google_storage_bucket.cloud_build_notifier.url}/${local.base_name}-config.yaml"
        }

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
      }
    }
  }

  autogenerate_revision_name = true

  lifecycle {
    # Ignored because Cloud Run may add annotations outside of this config
    ignore_changes = [
      metadata.0.annotations,
    ]
  }

  depends_on = [
    google_project_service.apis["run.googleapis.com"],
    google_secret_manager_secret_iam_member.notifier_secret_accessor
  ]
}


# ------------------------------------------------------------------------------
# Pub/Sub
# ------------------------------------------------------------------------------

# Create the cloud-builds topic to receive build update messages for your notifier
resource "google_pubsub_topic" "cloud_builds" {
  project = var.project_id
  name    = "cloud-builds"
}

resource "google_pubsub_subscription" "cloud_builds" {
  name    = local.base_name
  topic   = google_pubsub_topic.cloud_builds.name
  project = var.project_id

  push_config {
    push_endpoint = google_cloud_run_service.cloud_build_notifier.status[0].url

    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }
  }
}
