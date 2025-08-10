# Security Guide

This project is designed to keep your library private by default.

## IAM & Service Accounts

- Create a **dedicated service account** for the VM (e.g., `flac-sync-sa`).
- Grant only:
  - `roles/storage.objectViewer` on the bucket
  - `roles/pubsub.subscriber` on the subscription
- Avoid project-wide roles. Scope to the bucket and subscription resources.

## Secrets

- Do not commit credentials.
- Prefer:
  - **Secret Manager** for service account keys (if you must use keys).
  - Or attach the service account directly to the VM (no local keys).

## Network

- Do not expose SMB/NFS/HTTP to the public internet.
- Use **Tailscale** (or equivalent) for remote access.
- Restrict firewall rules to your private network ranges.

## Data Integrity

- Keep GCS as the **single source of truth** (recommended).
- Use `rclone check --one-way` in a scheduled job to catch drift.
