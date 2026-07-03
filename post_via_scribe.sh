#!/bin/bash
# Post approved caption + optional media to Buffer
# Usage: post_via_scribe.sh "caption" ["telegram_file_id_or_url"]
# If no file_id provided, reads from /root/.hermes/shared/latest_media.json automatically

source /root/.hermes/.env
CAPTION="$1"
MEDIA_INPUT="$2"

if [ -z "$CAPTION" ]; then
  echo "ERROR: No caption provided"
  exit 1
fi

# If no file_id passed, read from shared file automatically
if [ -z "$MEDIA_INPUT" ]; then
  if [ -f "/root/.hermes/shared/latest_media.json" ]; then
    MEDIA_INPUT=$(python3 -c "import json; d=json.load(open('/root/.hermes/shared/latest_media.json')); print(d['file_id']) if d.get('ready') else print('')")
    if [ -n "$MEDIA_INPUT" ]; then
      echo "Auto-loaded file_id from shared file: ${MEDIA_INPUT:0:20}..."
    fi
  fi
fi

MEDIA_URL=""

# Resolve Telegram file_id to CDN URL if needed
if [ -n "$MEDIA_INPUT" ]; then
  if [[ "$MEDIA_INPUT" == http* ]]; then
    MEDIA_URL="$MEDIA_INPUT"
    echo "Using provided URL: $MEDIA_URL"
  else
    echo "Resolving Telegram file_id to URL..."
    MEDIA_URL=$(python3 << PYEOF2
import requests, sys
token = "$TELEGRAM_BOT_TOKEN"
file_id = "$MEDIA_INPUT"
try:
    r = requests.get(f"https://api.telegram.org/bot{token}/getFile",
                     params={"file_id": file_id}, timeout=10)
    data = r.json()
    if data.get("ok"):
        file_path = data["result"]["file_path"]
        print(f"https://api.telegram.org/file/bot{token}/{file_path}")
    else:
        print("ERROR: " + str(data))
        sys.exit(1)
except Exception as e:
    print("ERROR: " + str(e))
    sys.exit(1)
PYEOF2
)
    if [[ "$MEDIA_URL" == ERROR* ]]; then
      echo "Failed to resolve file_id: $MEDIA_URL"
      echo "Falling back to text-only post on X"
      MEDIA_URL=""
    else
      echo "Resolved to: ${MEDIA_URL:0:60}..."
    fi
  fi
fi

# Post to X (always)
echo "--- Posting to X ---"
X_RESULT=$(bash /root/.hermes/scripts/buffer_post.sh "$CAPTION" "6a3ce7875ab6d2f1066d59c3" "$MEDIA_URL")
echo "$X_RESULT"

# Post to Instagram (only if media present)
if [ -n "$MEDIA_URL" ]; then
  echo "--- Posting to Instagram ---"
  IG_RESULT=$(bash /root/.hermes/scripts/buffer_post.sh "$CAPTION" "6a3a7ced5ab6d2f10661f4b1" "$MEDIA_URL")
  echo "$IG_RESULT"
else
  echo "--- Skipping Instagram (no media) ---"
  IG_RESULT='{"skipped": true}'
fi

# Final status
if echo "$X_RESULT" | grep -q '"id"'; then
  X_STATUS="X posted"
else
  X_STATUS="X failed"
fi

if echo "$IG_RESULT" | grep -q '"id"'; then
  IG_STATUS="Instagram posted"
elif echo "$IG_RESULT" | grep -q 'skipped'; then
  IG_STATUS="Instagram skipped (no media)"
else
  IG_STATUS="Instagram failed"
fi

echo ""
echo "=== POSTING SUMMARY ==="
echo "$X_STATUS"
echo "$IG_STATUS"
