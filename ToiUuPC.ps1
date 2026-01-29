param([switch]$Update)

chcp 65001 | Out-Null
[Console]::OutputEncoding = [Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"

$ROOT = Join-Path $env:TEMP "ToiUuPC"
$FUNC = Join-Path $ROOT "functions"
$CFG  = Join-Path $ROOT "config"

$dirs = @($ROOT,$FUNC,$CFG)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

function Get-File($url,$out) {
    Invoke-WebRequest $url -OutFile $out -UseBasicParsing
}

Write-Host "Dang dong bo ToiUuPC..."

$functions = @(
    "utils.ps1",
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1",
    "dns-management.ps1",
    "clean-system.ps1"
)

foreach ($f in $functions) {
    Get-File "$RepoRaw/functions/$f" (Join-Path $FUNC $f)
}

$configs = @("tweaks.json","applications.json","dns.json")
foreach ($c in $configs) {
    Get-File "$RepoRaw/config/$c" (Join-Path $CFG $c)
}

# SAFE dot-source
Get-ChildItem $FUNC -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

Clear-Host
Show-PMKLogo

while ($true) {
    Write-Host "1. Tweaks"
    Write-Host "2. Install apps"
    Write-Host "0. Exit"

    $c = Read-Host "Select"
    switch ($c) {
        "1" { Invoke-SystemTweaks -ConfigPath "$CFG\tweaks.json" }
        "2" { Invoke-AppInstaller -ConfigPath "$CFG\applications.json" }
        "0" { break }
    }
    pause
}
