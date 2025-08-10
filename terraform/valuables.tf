variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region (default: asia-northeast2 / Osaka)"
  type        = string
  default     = "asia-northeast2"
}

variable "bucket_name" {
  description = "GCS bucket name for FLAC master (must be globally unique)"
  type        = string
}

variable "gcs_prefix" {
  description = "Object key prefix as library root"
  type        = string
  default     = "flac-master/"
}

variable "pubsub_topic" {
  description = "Pub/Sub topic name for GCS object events"
  type        = string
  default     = "object-events"
}

variable "subscription_name" {
  description = "Subscriber name for the VM/NAS listener"
  type        = string
  default     = "object-events-sub"
}

variable "force_destroy" {
  description = "If true, destroy the bucket even if it contains objects (use for dev only)"
  type        = bool
  default     = false
}