# FLAC Cloud Stream

A cloud-based FLAC audio synchronization system designed for **secure, high-quality streaming** on both mobile and desktop devices.  
This project is optimized for **Google Cloud Platform (GCP)** and configured for the **northeast2 (Osaka)** region.

---

## Features

- **Event-driven synchronization**  
  Automatically detects file uploads to Google Cloud Storage (GCS) via Pub/Sub and syncs them to local or remote targets.
- **Lossless audio preservation**  
  Keeps the original FLAC format without conversion.
- **Streaming-ready**  
  Works seamlessly with apps like VLC, CloudBeats, or Evermusic for mobile and desktop playback.
- **Secure remote access**  
  Optional integration with [Tailscale](https://tailscale.com/) for encrypted connections to your library.
- **Flexible deployment**  
  Runs on GCP VM instances or local NAS systems.

---

## Architecture

See **[Architecture Details](docs/Architecture.md)**.

---

## Requirements

- Google Cloud Platform account
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.6+
- [rclone](https://rclone.org/)
- Python 3.8+ (for VM listener)
- Docker (optional, for containerized deployment or local testing)
- (For streaming) VLC, CloudBeats, or Evermusic

---

## Quick Start

1. Clone the repository

    ```bash
    git clone https://github.com/<your-github-username>/flac-cloud-stream.git
    cd flac-cloud-stream
    ```

    Replace `<your-github-username>` with your actual GitHub username or organization name.

1. Configure environment variables

    Copy `.env.example` to `.env` and set:

    ```env
    GCP_PROJECT_ID=your-project-id
    GCS_BUCKET_NAME=your-flac-bucket
    ```

1. Deploy GCP infrastructure (GCS + Pub/Sub)

    ```bash
    cd terraform
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars to match your environment
    terraform init
    terraform apply
    ```

1. Prepare the VM or NAS

    On the target VM/NAS (with access to GCS and Pub/Sub):

    ```bash
    cd vm
    sudo ./setup.sh
    ```

    - This script installs Python, rclone, and systemd units for continuous syncing.
    - Edit `/etc/default/flac-pull` to set your bucket, prefix, and rclone settings.
    - Ensure `rclone config` has a remote matching `$RCLONE_REMOTE_GCS` (default: `gcs`).
    > **Note:** VM setup steps will be provided after public release.  
    > Currently, the Terraform configuration covers infrastructure provisioning up to VM creation.

1. Start syncing service

    ```bash
    sudo systemctl enable --now flac-pull.service
    sudo systemctl enable --now flac-pull.timer
    ```

    - `flac-pull.service` listens to Pub/Sub and syncs files on events.
    - `flac-pull.timer` restarts the service if it stops.

1. Connect your streaming app

   - **Local network**: Use the VM/NAS IP in your streaming app.
   - **Remote**: Connect via Tailscale to the same IP or hostname.

---

## Directory Structure

```text
flac-cloud-stream/
├── README.md
├── terraform/       # GCP infrastructure definitions
├── vm/              # VM/NAS setup scripts
├── docs/            # Architecture diagrams & detailed docs
└── LICENSE
```

---

## License

This project is released under the MIT License.

---

## Contributing

Contributions are welcome!

- Open an issue for bug reports or feature requests.
- Submit a Pull Request for improvements.
- Help improve documentation or translations.

---

## Additional Documentation

- [Architecture Details](docs/Architecture.md)
- [Environment Variables Example](.env.example)
- [Security Guide](SECURITY.md)
- [Contributing Guidelines](CONTRIBUTING.md)

---

## Optional: Using Docker

Docker is **not required** for running flac-cloud-stream,  
but it can be useful for local testing or packaging the VM listener into a container.

### Example: Run Pub/Sub listener in Docker

```bash
docker build -t flac-cloud-stream-listener -f vm/Dockerfile .
docker run --rm \
    -e GCP_PROJECT_ID=your-project-id \
    -e PUBSUB_SUBSCRIPTION=object-events-sub \
    -e GCS_BUCKET_NAME=your-flac-bucket \
    -v $(pwd)/rclone.conf:/root/.config/rclone/rclone.conf \
    flac-cloud-stream-listener
```

### Benefits of Docker

- Easy local testing without polluting host environment
- Portable deployment target (Kubernetes, Cloud Run, etc.)
- Isolation of dependencies

> **Note**: For most home/NAS deployments, installing directly via vm/setup.sh is simpler.
