#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time
from typing import Dict, Any

from google.cloud import pubsub_v1

# ---- env ----
PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SUBSCRIPTION_ID = os.getenv("PUBSUB_SUBSCRIPTION", "object-events-sub")
GCS_BUCKET = os.getenv("GCS_BUCKET_NAME")
GCS_PREFIX = os.getenv("GCS_PREFIX", "flac-master/")

RCLONE_REMOTE_GCS = os.getenv("RCLONE_REMOTE_GCS", "gcs")
LOCAL_ROOT = os.getenv("LOCAL_LIBRARY_ROOT", "/srv/music")
LOCAL_PREFIX = os.getenv("LOCAL_PREFIX", "flac-master/")
RCLONE_FLAGS = os.getenv(
    "RCLONE_FLAGS", "--checksum --transfers=2 --checkers=4 --fast-list"
)

if not (PROJECT_ID and SUBSCRIPTION_ID and GCS_BUCKET and LOCAL_ROOT):
    print("Missing required envs. Check /etc/default/flac-pull",
          file=sys.stderr)
    sys.exit(1)

subscription_path = f"projects/{PROJECT_ID}/subscriptions/{SUBSCRIPTION_ID}"


# ---- helpers ----
def log(msg: str):
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] {msg}", flush=True)


def run(cmd: list[str]) -> int:
    log("Running: " + " ".join(cmd))
    return subprocess.run(cmd).returncode


def handle_event(payload: Dict[str, Any]) -> None:
    """Minimal handler: copy one object or prefix from GCS\
        -> local using rclone."""
    name = payload.get("name") or payload.get(
        "objectId"
    )  # JSON_API_V1 vs storage#object
    if not name:
        log("No object name in payload; skipping.")
        return

    # Prefix filter
    if not name.startswith(GCS_PREFIX):
        log(f"Skip: {name} not under prefix {GCS_PREFIX}")
        return

    # Build rclone source/dest
    # Source example: gcs:bucket/flac-master/Artist/Album/track.flac
    src = f"{RCLONE_REMOTE_GCS}:{GCS_BUCKET}/{name}"
    # Dest root: /srv/music/flac-master/
    dest_dir = os.path.join(LOCAL_ROOT, os.path.dirname(name))
    os.makedirs(dest_dir, exist_ok=True)

    # Copy only that file
    # (safer/faster than syncing the whole prefix per event)
    cmd = [
        "rclone",
        "copyto",
        src,
        os.path.join(LOCAL_ROOT, name),
    ] + RCLONE_FLAGS.split()
    rc = run(cmd)
    if rc == 0:
        log(f"✔ Synced: {name}")
    else:
        log(f"✖ Failed: {name} (rclone rc={rc})")


def main():
    subscriber = pubsub_v1.SubscriberClient()
    with subscriber:

        def callback(message: pubsub_v1.subscriber.message.Message) -> None:
            try:
                data = message.data.decode("utf-8")
                payload = json.loads(data)
                handle_event(payload)
                message.ack()
            except Exception as e:
                log(f"Error processing message: {e}")
                # Nack to retry later
                message.nack()

        streaming_pull_future = subscriber.subscribe(
            subscription_path, callback=callback
        )
        log(f"🚀 Subscribing: {subscription_path}")
        try:
            streaming_pull_future.result()
        except KeyboardInterrupt:
            streaming_pull_future.cancel()
            log("Shutting down.")


if __name__ == "__main__":
    main()
