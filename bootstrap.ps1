# ToiUuPC Bootstrap - SAFE MODE

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# Admin check
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Please run PowerShell as Administrator"
    pause
    exit 1
}

$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"
$WorkDir = Join-Path $env:TEMP "ToiUuPC"
$Main    = Join-Path $WorkDir "ToiUuPC.ps1"

if (-not (Test-Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir | Out-Null
}

Write-Host "Downloading ToiUuPC..."
Invoke-WebRequest "$RepoRaw/ToiUuPC.ps1" -OutFile $Main -UseBasicParsing

Write-Host "Launching..."
powershell -NoProfile -ExecutionPolicy Bypass -File $Main
