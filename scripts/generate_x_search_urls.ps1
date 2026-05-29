param(
  [string]$Handle = "octopusycc",
  [Parameter(Mandatory=$true)]
  [string]$Since,
  [Parameter(Mandatory=$true)]
  [string]$Until,
  [int]$WindowDays = 1,
  [string]$ExtraQuery = "",
  [string]$Output = ""
)

$start = [datetime]::Parse($Since)
$end = [datetime]::Parse($Until)
if ($end -le $start) { throw "Until must be after Since" }
if ($WindowDays -lt 1) { throw "WindowDays must be >= 1" }

if (-not $Output) {
  $safe = "$Handle`_$($start.ToString('yyyyMMdd'))_$($end.ToString('yyyyMMdd'))_urls.txt"
  $Output = Join-Path (Get-Location) $safe
}

$urls = New-Object System.Collections.Generic.List[string]
$cursor = $start
while ($cursor -lt $end) {
  $next = $cursor.AddDays($WindowDays)
  if ($next -gt $end) { $next = $end }

  $query = "from:$Handle since:$($cursor.ToString('yyyy-MM-dd')) until:$($next.ToString('yyyy-MM-dd'))"
  if ($ExtraQuery.Trim()) { $query = "$query $ExtraQuery" }
  $encoded = [System.Uri]::EscapeDataString($query)
  $urls.Add("https://x.com/search?q=$encoded&src=typed_query&f=live")
  $cursor = $next
}

[System.IO.File]::WriteAllLines($Output, $urls, [System.Text.UTF8Encoding]::new($false))
Write-Output $Output
