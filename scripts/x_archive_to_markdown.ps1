param(
  [Parameter(Mandatory=$true)]
  [string]$Archive,

  [string]$Output
)

$json = Get-Content -LiteralPath $Archive -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $Output) {
  $Output = [System.IO.Path]::ChangeExtension($Archive, ".md")
}

$lines = New-Object System.Collections.Generic.List[string]
$title = if ($json.handle) { $json.handle } elseif ($json.sourceUrl) { $json.sourceUrl } else { [System.IO.Path]::GetFileNameWithoutExtension($Archive) }
$lines.Add("# X Timeline Archive: $title")
$lines.Add("")
$lines.Add("- Source: $($json.sourceUrl)")
$lines.Add("- Started: $($json.startedAt)")
$lines.Add("- Finished: $($json.finishedAt)")
$lines.Add("- Count: $($json.tweets.Count)")
$lines.Add("")

$i = 1
foreach ($tweet in $json.tweets) {
  $text = [string]$tweet.text
  if ([string]::IsNullOrWhiteSpace($text)) { continue }

  $lines.Add("## $i. $($tweet.time)")
  $lines.Add("")
  if ($tweet.statusUrl) { $lines.Add("- URL: $($tweet.statusUrl)") }
  if ($tweet.userName) { $lines.Add("- User: $($tweet.userName)") }
  if ($tweet.media -and $tweet.media.Count -gt 0) {
    $lines.Add("- Media:")
    foreach ($m in $tweet.media) {
      if ($m.src) {
        if ([string]$m.src -match '^https://pbs\.twimg\.com/media/') {
          $lines.Add("  - ![media]($($m.src))")
        } else {
          $lines.Add("  - $($m.src)")
        }
      }
    }
  }
  $lines.Add("")
  $lines.Add($text.Trim())
  $lines.Add("")
  $i++
}

[System.IO.File]::WriteAllText($Output, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
Write-Output $Output
