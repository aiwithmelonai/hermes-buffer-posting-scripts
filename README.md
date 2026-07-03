# Hermes Buffer Posting Scripts
Automated social media posting via Buffer GraphQL API.
Part of the MELON AI automation stack — built to run a furniture
and interior design business on AI automation.

## What It Does

Send a photo on Telegram → AI analyses it → drafts captions
→ approve with one word → posts to Instagram and X within 60 seconds.

## Scripts

buffer_post.sh — Core Buffer GraphQL posting engine
  Handles image/video detection, Instagram metadata,
  schedules posts 1 minute from execution

post_via_scribe.sh — Entry point
  Auto-loads file_id from shared file
  Resolves Telegram file_id to CDN URL
  Posts to both Instagram and X

get_file_id.py — Media processor
  Finds most recent cached media
  Uploads to Telegram CDN to get file_id
  Writes to shared JSON file for scripts to read

media_watcher.py — Cron job (runs every minute)
  Detects new media in Hermes cache
  Triggers get_file_id.py automatically

## Usage

Text only (X only):
bash post_via_scribe.sh "Your caption here"

With manual file_id:
bash post_via_scribe.sh "Your caption" "AgAC..."

Auto mode (reads from shared file):
bash post_via_scribe.sh "Your caption"

## Requirements
- Buffer account with Instagram and X connected
- Telegram Bot with file caching enabled
- Python 3 with requests library
- Anthropic API key (for Hermes gateway model)

## Built by MELON AI
@aiwithmelonai — Building AI automations for real businesses
