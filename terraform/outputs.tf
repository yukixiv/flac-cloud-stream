output "bucket_name" {
  description = "GCS bucket (master library)"
  value       = google_storage_bucket.flac_master.name
}

output "pubsub_topic" {
  description = "Pub/Sub topic for GCS events"
  value       = google_pubsub_topic.gcs_events.name
}

output "subscription" {
  description = "Subscription used by the VM/NAS listener"
  value       = google_pubsub_subscription.gcs_events_sub.name
}