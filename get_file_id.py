#!/usr/bin/env python3
# get_file_id.py
# Finds most recent cached media, uploads to Telegram, saves file_id to shared file
import requests, glob, os, re, json
from datetime import datetime, timezone

env = open("/root/.hermes/.env").read()
t = re.search(r"TELEGRAM_BOT_TOKEN=(\S+)", env).group(1)
chat_id = re.search(r"TELEGRAM_HOME_CHANNEL=(\S+)", env).group(1)

files = glob.glob("/root/.hermes/image_cache/*.jpg") + glob.glob("/root/.hermes/image_cache/*.png")
videos = glob.glob("/root/.hermes/cache/videos/*.mp4") + glob.glob("/root/.hermes/cache/videos/*.mov")
all_files = files + videos

if not all_files:
    print("ERROR: No media found in cache")
    exit(1)

recent = max(all_files, key=os.path.getmtime)
is_video = recent.endswith((".mp4", ".mov"))
media_type = "video" if is_video else "image"
print(f"Found {media_type}: {recent}")

with open(recent, "rb") as f:
    if is_video:
        r = requests.post(f"https://api.telegram.org/bot{t}/sendVideo",
                         data={"chat_id": chat_id}, files={"video": f})
    else:
        r = requests.post(f"https://api.telegram.org/bot{t}/sendPhoto",
                         data={"chat_id": chat_id}, files={"photo": f})

result = r.json()
if result.get("ok"):
    if is_video:
        fid = result["result"]["video"]["file_id"]
    else:
        fid = result["result"]["photo"][-1]["file_id"]

    # Save to shared file for Orchestrator to read
    shared = {
        "file_id": fid,
        "media_type": media_type,
        "local_path": recent,
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "ready": True
    }
    os.makedirs("/root/.hermes/shared", exist_ok=True)
    with open("/root/.hermes/shared/latest_media.json", "w") as f:
        json.dump(shared, f, indent=2)

    print(f"FILE_ID: {fid}")
    print(f"Media type: {media_type}")
    print(f"Saved to: /root/.hermes/shared/latest_media.json")
else:
    print(f"ERROR: {result}")
    exit(1)
