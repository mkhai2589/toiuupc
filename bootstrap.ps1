# ==================================================
# bootstrap.ps1 – FINAL
# PMK Toolbox – ToiUuPC Bootstrap
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RepoUrl   = "https://github.com/mkhai2589/toiuupc"
$ZipUrl    = "$RepoUrl/archive/refs/heads/main.zip"
$TargetDir = Join-Path $env:TEMP "ToiUuPC"
$MainFile  = Join-Path $TargetDir "ToiUuPC.ps1"

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "Run PowerShell as Administrator." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir | Out-Null
}

function Test-Git {
    try { git --version *> $null; $true } catch { $false }
}

Write-Host "PMK Toolbox Bootstrap"
Write-Host "Path: $TargetDir"
Write-Host ""

if (Test-Git) {
    if (Test-Path "$TargetDir\.git") {
        Push-Location $TargetDir
        git pull --rebase
        Pop-Location
    } else {
        git clone $RepoUrl $TargetDir
    }
} else {
    $zip = "$env:TEMP\toiuupc.zip"
    $tmp = "$env:TEMP\toiuupc_tmp"
    Remove-Item $zip,$tmp -Recurse -Force -ErrorAction SilentlyContinue
    Invoke-WebRequest $ZipUrl -OutFile $zip
    Expand-Archive $zip $tmp
    Copy-Item "$tmp\toiuupc-main\*" $TargetDir -Recurse -Force
}

if (-not (Test-Path $MainFile)) {
    Write-Host "ToiUuPC.ps1 missing" -ForegroundColor Red
    exit 1
}

Set-Location $TargetDir
powershell -NoProfile -ExecutionPolicy Bypass -File $MainFile
