#!/bin/bash
# Buffer GraphQL posting script
# Usage: buffer_post.sh "caption text" "channel_id" ["media_url"]
source /root/.hermes/secrets/buffer.env
TEXT="$1"
CHANNEL_ID="$2"
MEDIA_URL="$3"
IG_CHANNEL_ID="6a3a7ced5ab6d2f10661f4b1"
if [ -z "$TEXT" ] || [ -z "$CHANNEL_ID" ]; then
  echo "ERROR: Missing required arguments."
  exit 1
fi
PAYLOAD=$(python3 << PYEOF
import json, datetime
text = """$TEXT"""
channel_id = "$CHANNEL_ID"
media_url = """$MEDIA_URL"""
is_instagram = (channel_id == "$IG_CHANNEL_ID")
due_at = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=1)).strftime('%Y-%m-%dT%H:%M:%S.000Z')
if media_url.strip():
    if any(media_url.lower().endswith(ext) for ext in ['.mp4', '.mov', '.avi', '.webm']):
        assets_block = ', assets: [{ video: { url: ' + json.dumps(media_url.strip()) + ' } }]'
    else:
        assets_block = ', assets: [{ image: { url: ' + json.dumps(media_url.strip()) + ' } }]'
else:
    assets_block = ''
if is_instagram:
    metadata_block = ', metadata: { instagram: { type: post, shouldShareToFeed: true } }'
else:
    metadata_block = ''
mutation = """mutation CreatePost {
  createPost(input: {
    text: %s,
    channelId: %s,
    schedulingType: automatic,
    mode: customScheduled,
    dueAt: "%s"%s%s
  }) {
    ... on PostActionSuccess { post { id text dueAt } }
    ... on MutationError { message }
  }
}""" % (json.dumps(text), json.dumps(channel_id), due_at, assets_block, metadata_block)
print(json.dumps({'query': mutation}))
PYEOF
)
RESPONSE=$(curl -s -X POST https://api.buffer.com/graphql \
  -H "Authorization: Bearer $BUFFER_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")
echo "$RESPONSE"
if echo "$RESPONSE" | grep -q '"id"'; then
  echo "SUCCESS: Post scheduled for 1 minute from now"
else
  echo "ERROR: Post may have failed — check response above"
fi
