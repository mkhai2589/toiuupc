# bootstrap.ps1
# ToiUuPC Bootstrap Loader

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ----- Admin check -----
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Start-Process powershell `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# ----- Paths -----
$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"
$Root = Join-Path $env:TEMP "ToiUuPC"

if (-not (Test-Path $Root)) {
    New-Item -ItemType Directory -Path $Root | Out-Null
}

$MainFile = Join-Path $Root "ToiUuPC-Bundled.ps1"

Write-Host "Downloading ToiUuPC..."
Invoke-WebRequest `
    -Uri "$RepoRaw/ToiUuPC-Bundled.ps1" `
    -OutFile $MainFile `
    -UseBasicParsing

Write-Host "Launching..."
powershell `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $MainFile
