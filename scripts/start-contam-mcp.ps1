param(
  [switch]$Check
)

$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
  [Console]::Error.WriteLine($Message)
  exit 1
}

function Assert-Path([string]$Name, [string]$PathValue, [string]$PathType) {
  if ([string]::IsNullOrWhiteSpace($PathValue)) {
    Fail "$Name is not set."
  }
  if (-not (Test-Path -LiteralPath $PathValue -PathType $PathType)) {
    Fail "$Name does not exist: $PathValue"
  }
}

function Assert-OptionalPath([string]$Name, [string]$PathValue, [string]$PathType) {
  if (-not [string]::IsNullOrWhiteSpace($PathValue)) {
    if (-not (Test-Path -LiteralPath $PathValue -PathType $PathType)) {
      Fail "$Name does not exist: $PathValue"
    }
  }
}

function Use-ContamHomeCandidate([string]$PathValue) {
  if ([string]::IsNullOrWhiteSpace($PathValue)) {
    return $false
  }

  $candidate = Resolve-Path -LiteralPath $PathValue -ErrorAction SilentlyContinue
  if ($null -eq $candidate) {
    return $false
  }

  $contamx = Join-Path $candidate.Path "contamx3.exe"
  if (-not (Test-Path -LiteralPath $contamx -PathType Leaf)) {
    return $false
  }

  $env:CONTAM_HOME = $candidate.Path
  return $true
}

$node = Get-Command "node" -ErrorAction SilentlyContinue
if ($null -eq $node) {
  Fail "node is not available on PATH."
}

$pluginRoot = $env:CONTAM_PLUGIN_ROOT
Assert-Path "CONTAM_PLUGIN_ROOT" $pluginRoot "Container"

$serverPath = Join-Path $pluginRoot "contam-mcp\src\server.js"
Assert-Path "CONTAM_PLUGIN_ROOT\contam-mcp\src\server.js" $serverPath "Leaf"

if ([string]::IsNullOrWhiteSpace($env:CONTAM_HOME)) {
  [void](Use-ContamHomeCandidate $env:CONTAM_CHINESE_HOME)
}
if ([string]::IsNullOrWhiteSpace($env:CONTAM_HOME)) {
  [void](Use-ContamHomeCandidate $pluginRoot)
}

Assert-OptionalPath "CONTAM_HOME" $env:CONTAM_HOME "Container"
Assert-OptionalPath "CONTAM_CHINESE_HOME" $env:CONTAM_CHINESE_HOME "Container"
Assert-OptionalPath "CONTAMX_PATH" $env:CONTAMX_PATH "Leaf"
Assert-OptionalPath "CONTAMW_PATH" $env:CONTAMW_PATH "Leaf"
Assert-OptionalPath "PRJUP_PATH" $env:PRJUP_PATH "Leaf"
Assert-OptionalPath "SIMREAD_PATH" $env:SIMREAD_PATH "Leaf"
Assert-OptionalPath "SIMCOMP_PATH" $env:SIMCOMP_PATH "Leaf"

if ($Check) {
  Write-Output "OK: node"
  Write-Output "OK: CONTAM_PLUGIN_ROOT"
  if (-not [string]::IsNullOrWhiteSpace($env:CONTAM_HOME)) { Write-Output "OK: CONTAM_HOME" }
  if (-not [string]::IsNullOrWhiteSpace($env:CONTAM_CHINESE_HOME)) { Write-Output "OK: CONTAM_CHINESE_HOME" }
  Write-Output "OK: CONTAM Plugin wrapper paths are valid."
  exit 0
}

& $node.Source $serverPath
if ($LASTEXITCODE -ne $null) {
  exit $LASTEXITCODE
}
