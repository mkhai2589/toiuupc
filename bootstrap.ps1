# ==================================================
# bootstrap.ps1
# PMK Toolbox - ToiUuPC Bootstrap Loader
# Author: Minh Khai (PMK)
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ==================================================
# CONFIG
# ==================================================
$RepoUrl   = "https://github.com/mkhai2589/toiuupc.git"
$RepoRaw   = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"
$TargetDir = Join-Path $env:TEMP "ToiUuPC"
$MainFile  = Join-Path $TargetDir "ToiUuPC.ps1"

# ==================================================
# HELPER: ADMIN CHECK
# ==================================================
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "Vui long chay PowerShell bang quyen Administrator" -ForegroundColor Red
    Write-Host "➡ Right-click → Run as administrator"
    pause
    exit 1
}

# ==================================================
# HELPER: GIT CHECK
# ==================================================
function Test-Git {
    try {
        git --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

# ==================================================
# DOWNLOAD FILE (RAW)
# ==================================================
function Download-File {
    param(
        [string]$Url,
        [string]$Out
    )

    Invoke-WebRequest `
        -Uri $Url `
        -OutFile $Out `
        -UseBasicParsing `
        -Headers @{ "Cache-Control" = "no-cache" }
}

# ==================================================
# ENSURE TARGET DIR
# ==================================================
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

Write-Host "PMK Toolbox Bootstrap" -ForegroundColor Cyan
Write-Host "Install path: $TargetDir"
Write-Host ""

# ==================================================
# CLONE / UPDATE
# ==================================================
if (Test-Git) {

    if (Test-Path (Join-Path $TargetDir ".git")) {
        Write-Host "Dang cap nhat ToiUuPC (git pull)..."
        Push-Location $TargetDir
        git pull --rebase
        Pop-Location
    }
    else {
        Write-Host "⬇ Dang clone ToiUuPC..."
        git clone $RepoUrl $TargetDir
    }

}
else {
    Write-Host "⚠ Git khong ton tai → fallback RAW mode" -ForegroundColor Yellow

    $folders = @(
        "functions",
        "config",
        "ui"
    )

    foreach ($f in $folders) {
        New-Item -ItemType Directory `
            -Path (Join-Path $TargetDir $f) `
            -Force | Out-Null
    }

    $files = @(
        "ToiUuPC.ps1",
        "bootstrap.ps1",
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
        $out = Join-Path $TargetDir $file
        $url = "$RepoRaw/$file"

        try {
            Write-Host "⬇ $file"
            Download-File $url $out
        } catch {
            Write-Host "Loi tai: $file" -ForegroundColor Red
        }
    }
}

# ==================================================
# VERIFY MAIN FILE
# ==================================================
if (-not (Test-Path $MainFile)) {
    Write-Host "Khong tim thay ToiUuPC.ps1" -ForegroundColor Red
    pause
    exit 1
}

# ==================================================
# RUN TOOL
# ==================================================
Write-Host ""
Write-Host "Khoi dong PMK Toolbox..." -ForegroundColor Green
Write-Host ""

Set-Location $TargetDir
powershell `
    -ExecutionPolicy Bypass `
    -NoProfile `
    -File $MainFile
