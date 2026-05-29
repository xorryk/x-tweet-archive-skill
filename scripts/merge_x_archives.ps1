param(
  [Parameter(Mandatory=$true)]
  [string]$InputDir,

  [string]$Output = ""
)

if (-not (Test-Path -LiteralPath $InputDir)) { throw "InputDir not found: $InputDir" }
if (-not $Output) { $Output = Join-Path $InputDir "merged_x_archive.json" }

$files = Get-ChildItem -LiteralPath $InputDir -Filter "*.json" -File | Sort-Object Name
$seen = @{}
$tweets = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
  try {
    $data = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch {
    Write-Warning "Skip invalid JSON: $($file.FullName)"
    continue
  }
  foreach ($tweet in @($data.tweets)) {
    $key = if ($tweet.statusUrl) { [string]$tweet.statusUrl } else { "$($tweet.time):$(([string]$tweet.text).Substring(0, [Math]::Min(120, ([string]$tweet.text).Length)))" }
    if (-not $seen.ContainsKey($key)) {
      $seen[$key] = $true
      $tweets.Add($tweet)
    }
  }
}

$sorted = @($tweets | Sort-Object time -Descending)
$merged = [ordered]@{
  source = "merged X archives"
  inputDir = $InputDir
  mergedAt = (Get-Date).ToUniversalTime().ToString("o")
  count = $sorted.Count
  tweets = $sorted
}

$json = $merged | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($Output, $json, [System.Text.UTF8Encoding]::new($false))
Write-Output $Output
