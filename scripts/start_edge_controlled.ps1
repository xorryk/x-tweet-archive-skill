param(
  [int]$Port = 9222,
  [string]$ProfileDir = "",
  [string]$Url = "https://x.com/octopusycc/"
)

$edgePaths = @(
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)

$edgePath = $edgePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $edgePath) { throw "Microsoft Edge was not found in the standard install paths." }

if (-not $ProfileDir) {
  $ProfileDir = Join-Path $PSScriptRoot "edge-control-profile"
}

$resolvedProfile = [System.IO.Path]::GetFullPath($ProfileDir)
New-Item -ItemType Directory -Force -Path $resolvedProfile | Out-Null

$versionUrl = "http://127.0.0.1:$Port/json/version"
try {
  $existing = Invoke-RestMethod -Uri $versionUrl -TimeoutSec 1
  Write-Output "Edge remote debugging is already available on port $Port"
  Write-Output $existing.webSocketDebuggerUrl
  exit 0
} catch {
  # Start a new controlled Edge profile below.
}

$args = @(
  "--remote-debugging-port=$Port",
  "--remote-allow-origins=*",
  "--user-data-dir=$resolvedProfile",
  "--no-first-run",
  "--no-default-browser-check",
  $Url
)

Start-Process -FilePath $edgePath -ArgumentList $args
Write-Output "Started controlled Edge on port $Port"
Write-Output "Profile: $resolvedProfile"
Write-Output "Open this window, log in to X if needed, then run capture_x_edge.ps1"
