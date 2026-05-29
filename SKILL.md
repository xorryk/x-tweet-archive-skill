---
name: x-tweet-archive
description: Capture visible X/Twitter profile or search-result timelines into deduplicated JSON archives and Markdown reports using a controlled Edge browser. Use when the user asks to fetch, scrape, archive, collect, export, or summarize tweets/posts from an X handle or X search URL, especially when they want media URLs preserved and output organized as Markdown.
---

# X Tweet Archive

## Overview

Use this skill to collect public X content that is visible in a user-authenticated browser session. The workflow starts a separate Microsoft Edge profile with Chrome DevTools Protocol enabled, lets the user log in if needed, captures rendered tweet cards, and exports JSON plus Markdown.

Do not read or extract cookies, tokens, passwords, DMs, or the user's default browser profile. Use the isolated controlled Edge profile unless the user explicitly provides another remote-debugging browser endpoint.

## Scripts

- `scripts/start_edge_controlled.ps1`: start an isolated Edge window on a remote-debugging port.
- `scripts/generate_x_search_urls.ps1`: generate date-window X search URLs such as `from:handle since:YYYY-MM-DD until:YYYY-MM-DD`.
- `scripts/capture_x_edge.ps1`: connect to the controlled Edge instance and capture one URL or a file of URLs.
- `scripts/merge_x_archives.ps1`: merge JSON archives and dedupe by `statusUrl`.
- `scripts/x_archive_to_markdown.ps1`: convert a JSON archive to Markdown, preserving tweet text, status URLs, metrics, and media URLs.

## Workflow

1. Resolve the skill directory, then run scripts from its `scripts/` folder.
2. Start controlled Edge:

```powershell
powershell -ExecutionPolicy Bypass -File <skill>\scripts\start_edge_controlled.ps1 -Url https://x.com/<handle>/
```

Ask the user to log in inside that separate Edge window if X is not already logged in.

3. For a profile or single search URL, capture directly:

```powershell
powershell -ExecutionPolicy Bypass -File <skill>\scripts\capture_x_edge.ps1 -Handle <handle> -Url https://x.com/<handle>/ -Rounds 80 -OutputDir <output-dir>
```

4. For a reliable historical archive, prefer date-window search URLs:

```powershell
powershell -ExecutionPolicy Bypass -File <skill>\scripts\generate_x_search_urls.ps1 -Handle <handle> -Since 2026-04-30 -Until 2026-05-31 -WindowDays 1 -Output <output-dir>\<handle>_urls.txt
powershell -ExecutionPolicy Bypass -File <skill>\scripts\capture_x_edge.ps1 -Handle <handle> -UrlsFile <output-dir>\<handle>_urls.txt -Rounds 12 -OutputDir <output-dir>
```

Use `Until` as the day after the final desired date because X search treats `until:` as exclusive.

5. Merge multiple captures when needed:

```powershell
powershell -ExecutionPolicy Bypass -File <skill>\scripts\merge_x_archives.ps1 -InputDir <json-folder> -Output <output-dir>\merged_x_archive.json
```

6. Convert to Markdown:

```powershell
powershell -ExecutionPolicy Bypass -File <skill>\scripts\x_archive_to_markdown.ps1 <output-dir>\merged_x_archive.json
```

## Validation Checks

After capture, report:

- total tweets
- tweets missing `time`
- earliest and latest timestamps
- observed dates and missing dates for the requested range
- tweets with media and total media item count
- output JSON and Markdown paths

If X search returns zero for a date window, retry with a wider two-day window before concluding there may be no visible posts for that day.

## Notes

- X profile infinite scroll can skip dates; date-window search is more reliable.
- X may still omit posts due to search ranking, rate limits, deleted posts, protected posts, or visibility restrictions.
- Captured media are URLs from rendered cards; the scripts do not download images or videos.
- Browser navigation warnings such as `ERR_ABORTED` can be harmless when X SPA navigation continues and tweet cards render.
