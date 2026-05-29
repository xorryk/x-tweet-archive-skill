param(
  [int]$Port = 9222,
  [string]$Handle = "octopusycc",
  [string]$Url = "https://x.com/octopusycc/",
  [string]$UrlsFile = "",
  [int]$Rounds = 80,
  [int]$DelayMs = 1500,
  [string]$OutputDir = "$env:USERPROFILE\Downloads",
  [string]$NodePath = "",
  [string]$NodeModules = "",
  [string]$PnpmNodeModules = ""
)

$runtimeRoot = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node"
$node = if ($NodePath) { $NodePath } else { Join-Path $runtimeRoot "bin\node.exe" }
$nodeModules = if ($NodeModules) { $NodeModules } else { Join-Path $runtimeRoot "node_modules" }
$pnpmNodeModules = if ($PnpmNodeModules) { $PnpmNodeModules } else { Join-Path $runtimeRoot "node_modules\.pnpm\node_modules" }
if (-not (Test-Path -LiteralPath $node)) { throw "Bundled Node.js not found: $node" }
if (-not (Test-Path -LiteralPath $nodeModules)) { throw "Bundled node_modules not found: $nodeModules" }
if (-not (Test-Path -LiteralPath $pnpmNodeModules)) { throw "Bundled pnpm node_modules not found: $pnpmNodeModules" }

$env:NODE_PATH = "$nodeModules;$pnpmNodeModules"
$script = Join-Path $PSScriptRoot "capture_x_edge_cdp.cjs"

$args = @(
  $script,
  "--port", "$Port",
  "--handle", $Handle,
  "--rounds", "$Rounds",
  "--delayMs", "$DelayMs",
  "--out", $OutputDir
)

if ($UrlsFile) {
  $args += @("--urlsFile", $UrlsFile)
} else {
  $args += @("--url", $Url)
}

& $node $args
