# ---------- Provider ----------
provider "google" {
  project = var.project_id
  region  = var.region
}

# Project info (used for outputs or references)
data "google_project" "this" {}

# ---------- Enable required APIs (do not disable on destroy) ----------
resource "google_project_service" "enable_storage" {
  project = var.project_id
  service = "storage.googleapis.com"
}

resource "google_project_service" "enable_pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"
}

# ---------- GCS bucket (master) ----------
resource "google_storage_bucket" "flac_master" {
  name                        = var.bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  versioning { enabled = true }

  # Example lifecycle rule (optional)
  # lifecycle_rule {
  #   action    { type = "Delete" }
  #   condition { age = 3650, with_state = "ARCHIVED" }
  # }

  depends_on = [google_project_service.enable_storage]
}

# ---------- Pub/Sub ----------
resource "google_pubsub_topic" "gcs_events" {
  name       = var.pubsub_topic
  depends_on = [google_project_service.enable_pubsub]
}

resource "google_pubsub_subscription" "gcs_events_sub" {
  name  = var.subscription_name
  topic = google_pubsub_topic.gcs_events.name

  ack_deadline_seconds       = 20
  message_retention_duration = "604800s" # 7 days
  retain_acked_messages      = false
}

# GCS publishes to Pub/Sub via the project storage SA
data "google_storage_project_service_account" "gcs" {
  project    = var.project_id
  depends_on = [google_project_service.enable_storage]
}

resource "google_pubsub_topic_iam_member" "allow_gcs_publish" {
  topic  = google_pubsub_topic.gcs_events.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

# ---------- Bucket notification (GCS -> Pub/Sub) ----------
resource "google_storage_notification" "notify_to_pubsub" {
  bucket         = google_storage_bucket.flac_master.name
  topic          = google_pubsub_topic.gcs_events.id
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE", "OBJECT_METADATA_UPDATE"]
  object_name_prefix = var.gcs_prefix

  depends_on = [google_pubsub_topic_iam_member.allow_gcs_publish]
}