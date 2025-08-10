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
- [Docker](https://www.docker.com/)
- [rclone](https://rclone.org/)
- (For streaming) VLC, CloudBeats, or Evermusic

---

## Quick Start

1. Clone the repository

    ```bash
    git clone https://github.com/<your-github-username>/flac-cloud-stream.git
    cd flac-cloud-stream
    ```

    Replace `<your-github-username>` with your actual GitHub username or organization name.

2. Configure environment variables

    Copy `.env.example` to `.env` and set:

    ```env
    GCP_PROJECT_ID=your-project-id
    GCS_BUCKET_NAME=your-flac-bucket
    ```

3. Deploy infrastructure

    ```bash
    cd terraform
    terraform init
    terraform apply
    ```

4. Set up the VM or NAS

    ```bash
    cd vm
    ./setup.sh
    ```

5. Connect your streaming app
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

This project will be released under either the MIT License or Apache 2.0 License.

---

## Contributing

Contributions are welcome!

- Open an issue for bug reports or feature requests.
- Submit a Pull Request for improvements.
- Help improve documentation or translations.

---

## Additional Documentation

- [Architecture Details](docs/ARCHITECTURE.md)
- [Environment Variables Example](.env.example)
- [Security Guide](SECURITY.md)
- [Contributing Guidelines](CONTRIBUTING.md)

---
