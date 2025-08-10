#!/usr/bin/env bash
set -euo pipefail

# ----- config -----
APP_DIR="/opt/flac-cloud-stream"
PY_ENV="${APP_DIR}/.venv"
SERVICE_USER="flacsync"

# Create user if not exists
if ! id -u "${SERVICE_USER}" >/dev/null 2>&1; then
  sudo useradd -r -s /usr/sbin/nologin "${SERVICE_USER}"
fi

# Create app dir
sudo mkdir -p "${APP_DIR}" /var/log/flac-cloud-stream
sudo chown -R "${SERVICE_USER}:${SERVICE_USER}" "${APP_DIR}" /var/log/flac-cloud-stream

# Copy files
sudo install -m 0644 requirements.txt "${APP_DIR}/requirements.txt"
sudo install -m 0755 pull_pubsub.py "${APP_DIR}/pull_pubsub.py"

# Python venv
sudo apt-get update -y
sudo apt-get install -y python3-venv jq
sudo -u "${SERVICE_USER}" python3 -m venv "${PY_ENV}"
sudo -u "${SERVICE_USER}" "${PY_ENV}/bin/pip" install --upgrade pip
sudo -u "${SERVICE_USER}" "${PY_ENV}/bin/pip" install -r "${APP_DIR}/requirements.txt"

# rclone (if not installed)
if ! command -v rclone >/dev/null 2>&1; then
  curl -fsSL https://rclone.org/install.sh | sudo bash
fi

# systemd unit
sudo mkdir -p /etc/systemd/system/flac-pull.d
sudo tee /etc/systemd/system/flac-pull.service >/dev/null <<'UNIT'
[Unit]
Description=FLAC Cloud Stream - Pub/Sub pull & rclone sync
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=flacsync
Group=flacsync
WorkingDirectory=/opt/flac-cloud-stream
Environment=PY_ENV=/opt/flac-cloud-stream/.venv
EnvironmentFile=-/etc/default/flac-pull
ExecStart=/bin/bash -lc '$PY_ENV/bin/python /opt/flac-cloud-stream/pull_pubsub.py'
Restart=always
RestartSec=5s
StandardOutput=append:/var/log/flac-cloud-stream/pull.log
StandardError=append:/var/log/flac-cloud-stream/pull.err
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
UNIT

sudo tee /etc/systemd/system/flac-pull.timer >/dev/null <<'TIMER'
[Unit]
Description=Kick flac-pull if it ever exits

[Timer]
OnBootSec=10s
OnUnitInactiveSec=30s
Unit=flac-pull.service

[Install]
WantedBy=timers.target
TIMER

# default envs (edit as needed)
sudo tee /etc/default/flac-pull >/dev/null <<'ENV'
# ----- Required envs -----
GCP_PROJECT_ID=
PUBSUB_SUBSCRIPTION=object-events-sub
GCS_BUCKET_NAME=
GCS_PREFIX=flac-master/

# rclone remotes (must exist via `rclone config`)
RCLONE_REMOTE_GCS=gcs
LOCAL_LIBRARY_ROOT=/srv/music
LOCAL_PREFIX=flac-master/

# rclone flags
RCLONE_FLAGS=--checksum --transfers=2 --checkers=4 --fast-list
ENV

sudo systemctl daemon-reload
sudo systemctl enable --now flac-pull.service
sudo systemctl enable --now flac-pull.timer

echo "Done. Edit /etc/default/flac-pull and restart: sudo systemctl restart flac-pull.service"