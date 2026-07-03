#!/usr/bin/env python3
# media_watcher.py
# Runs every minute via cron. If new media arrived, runs get_file_id.py
import glob, os, json
from datetime import datetime, timezone

SHARED = "/root/.hermes/shared/latest_media.json"
IMAGE_CACHE = "/root/.hermes/image_cache"
VIDEO_CACHE = "/root/.hermes/cache/videos"

files = (glob.glob(f"{IMAGE_CACHE}/*.jpg") +
         glob.glob(f"{IMAGE_CACHE}/*.png") +
         glob.glob(f"{VIDEO_CACHE}/*.mp4") +
         glob.glob(f"{VIDEO_CACHE}/*.mov"))

if not files:
    exit(0)

most_recent = max(files, key=os.path.getmtime)
most_recent_time = os.path.getmtime(most_recent)

# Check if we already processed this file
if os.path.exists(SHARED):
    with open(SHARED) as f:
        existing = json.load(f)
    last_path = existing.get("local_path", "")
    if last_path == most_recent and existing.get("ready"):
        # Already processed this file
        exit(0)

# New file found — process it
print(f"New media detected: {most_recent}")
os.system("python3 /root/.hermes/scripts/get_file_id.py")
