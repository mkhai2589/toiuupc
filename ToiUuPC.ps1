param([switch]$Update)

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"

$ROOT = Join-Path $env:TEMP "ToiUuPC"
$FUNC = Join-Path $ROOT "functions"
$CFG  = Join-Path $ROOT "config"

foreach ($d in @($ROOT,$FUNC,$CFG)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
    }
}

function Get-File {
    param($Url,$Out)
    Invoke-WebRequest $Url -OutFile $Out -UseBasicParsing
}

Write-Host "Dang dong bo ToiUuPC..."

$FunctionFiles = @(
    "utils.ps1",
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1",
    "dns-management.ps1",
    "clean-system.ps1"
)

foreach ($f in $FunctionFiles) {
    Get-File "$RepoRaw/functions/$f" (Join-Path $FUNC $f)
}

$ConfigFiles = @(
    "tweaks.json",
    "applications.json",
    "dns.json"
)

foreach ($c in $ConfigFiles) {
    Get-File "$RepoRaw/config/$c" (Join-Path $CFG $c)
}

Get-ChildItem $FUNC -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

Clear-Host
Show-PMKLogo

while ($true) {
    Write-Host ""
    Write-Host "1. Toi uu Windows"
    Write-Host "2. Cai ung dung"
    Write-Host "3. Quan ly DNS"
    Write-Host "4. Don dep he thong"
    Write-Host "0. Thoat"

    $c = Read-Host "Chon chuc nang"

    switch ($c) {
        "1" { Invoke-SystemTweaks -ConfigPath "$CFG\tweaks.json" }
        "2" { Invoke-AppInstaller -ConfigPath "$CFG\applications.json" }
        "3" { Start-DnsManager -ConfigPath "$CFG\dns.json" }
        "4" { Invoke-CleanSystem -All }
        "0" { break }
    }

    pause
}
