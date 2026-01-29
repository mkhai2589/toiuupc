# ==================================================
# PMK Toolbox Bootstrap (SILENT MODE)
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# ==================================================
# CONFIG
# ==================================================
$RepoUrl   = "https://github.com/mkhai2589/toiuupc.git"
$RepoRaw   = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"
$TargetDir = Join-Path $env:TEMP "ToiUuPC"
$MainFile  = Join-Path $TargetDir "ToiUuPC.ps1"

# ==================================================
# ADMIN CHECK
# ==================================================
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "Please run PowerShell as Administrator" -ForegroundColor Red
    exit 1
}

# ==================================================
# GIT CHECK
# ==================================================
function Test-Git {
    try { git --version *> $null; $true } catch { $false }
}

# ==================================================
# DOWNLOAD FILE (SILENT)
# ==================================================
function Download-File {
    param($Url, $Out)
    Invoke-WebRequest `
        -Uri $Url `
        -OutFile $Out `
        -UseBasicParsing `
        -Headers @{ "Cache-Control" = "no-cache" } `
        -ErrorAction Stop `
        *> $null
}

# ==================================================
# PREPARE DIR
# ==================================================
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

Write-Host "PMK Toolbox Bootstrap" -ForegroundColor Cyan
Write-Host "Install path: $TargetDir"
Write-Host ""

# ==================================================
# INSTALL
# ==================================================
if (Test-Git) {

    if (Test-Path (Join-Path $TargetDir ".git")) {
        Push-Location $TargetDir
        git pull --rebase *> $null
        Pop-Location
    } else {
        git clone $RepoUrl $TargetDir *> $null
    }

} else {

    Write-Host "Git not found — using RAW mode" -ForegroundColor Yellow

    $folders = "functions","config","ui"
    foreach ($f in $folders) {
        New-Item -ItemType Directory -Path (Join-Path $TargetDir $f) -Force | Out-Null
    }

    $files = @(
        "ToiUuPC.ps1",
        "functions/utils.ps1",
        "functions/tweaks.ps1",
        "functions/install-apps.ps1",
        "functions/dns-management.ps1",
        "functions/clean-system.ps1",
        "functions/dashboard-engine.ps1",
        "functions/Show-PMKLogo.ps1",
        "config/tweaks.json",
        "config/applications.json",
        "config/dns.json",
        "ui/Dashboard.xaml"
    )

    foreach ($file in $files) {
        Download-File "$RepoRaw/$file" (Join-Path $TargetDir $file)
    }
}

# ==================================================
# RUN
# ==================================================
Write-Host ""
Write-Host "Launching PMK Toolbox..." -ForegroundColor Green

Set-Location $TargetDir
powershell -ExecutionPolicy Bypass -NoProfile -File $MainFile
