# x-tweet-archive Skill

Codex skill for capturing visible X/Twitter timelines from a controlled Microsoft Edge session and exporting deduplicated JSON plus Markdown reports.

## What is included

- `SKILL.md`: Codex skill instructions.
- `scripts/start_edge_controlled.ps1`: starts isolated Edge with remote debugging enabled.
- `scripts/capture_x_edge.ps1`: PowerShell wrapper for capture.
- `scripts/capture_x_edge_cdp.cjs`: Chrome DevTools Protocol capture script.
- `scripts/generate_x_search_urls.ps1`: builds date-window X search URLs.
- `scripts/merge_x_archives.ps1`: merges and deduplicates JSON archives.
- `scripts/x_archive_to_markdown.ps1`: converts archives to Markdown.
- `agents/openai.yaml`: optional agent metadata.

## What is not included

This repo intentionally excludes captured tweets, media downloads, browser profiles, cookies, tokens, passwords, DMs, and local run outputs.

## Install

Copy this folder to:

```text
C:\Users\<you>\.codex\skills\x-tweet-archive
```

Restart Codex if the skill list does not refresh automatically.

## Basic Usage

Start the controlled browser:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_edge_controlled.ps1 -Url https://x.com/<handle>/
```

Capture a profile or search URL:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\capture_x_edge.ps1 -Handle <handle> -Url https://x.com/<handle>/ -Rounds 80 -OutputDir .\runs
```

For more complete historical capture, generate date-window searches first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\generate_x_search_urls.ps1 -Handle <handle> -Since 2026-04-30 -Until 2026-05-31 -WindowDays 1 -Output .\runs\<handle>_urls.txt
powershell -ExecutionPolicy Bypass -File .\scripts\capture_x_edge.ps1 -Handle <handle> -UrlsFile .\runs\<handle>_urls.txt -Rounds 12 -OutputDir .\runs
```

Merge and convert:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\merge_x_archives.ps1 -InputDir .\runs -Output .\runs\merged_x_archive.json
powershell -ExecutionPolicy Bypass -File .\scripts\x_archive_to_markdown.ps1 .\runs\merged_x_archive.json
```

## Safety

Use an isolated controlled Edge profile. Do not scrape or export browser cookies, tokens, saved passwords, direct messages, or private content.
