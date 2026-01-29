# ==================================================
# bootstrap.ps1
# PMK Toolbox – ToiUuPC Bootstrap Installer
# ==================================================

# --------------------------------------------------
# UTF8 / Encoding Setup
# --------------------------------------------------
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'   # Suppress progress output

# --------------------------------------------------
# CONFIGURATION
# --------------------------------------------------
$RepoRaw   = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"
$TargetDir = Join-Path $env:TEMP "ToiUuPC"
$MainFile  = Join-Path $TargetDir "ToiUuPC.ps1"

# List of files to download
$FilesToDownload = @(
    "ToiUuPC.ps1",
    "bootstrap.ps1",
    "functions/utils.ps1",
    "functions/Show-PMKLogo.ps1",
    "functions/tweaks.ps1",
    "functions/install-apps.ps1",
    "functions/dns-management.ps1",
    "functions/clean-system.ps1",
    "functions/dashboard-engine.ps1",
    "config/tweaks.json",
    "config/applications.json",
    "config/dns.json",
    "ui/Dashboard.xaml"
)

# --------------------------------------------------
# ADMIN CHECK
# --------------------------------------------------
function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($id)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

if (-not (Test-IsAdmin)) {
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    exit 1
}

# --------------------------------------------------
# DOWNLOAD HELPER
# --------------------------------------------------
function Download-File {
    param(
        [string]$RelativePath,
        [string]$Destination
    )

    $url = "$RepoRaw/$RelativePath"

    try {
        Invoke-WebRequest `
            -Uri $url `
            -OutFile $Destination `
            -UseBasicParsing `
            -ErrorAction Stop
        return $true
    } catch {
        Write-Host "Failed to download: $RelativePath" -ForegroundColor Red
        return $false
    }
}

# --------------------------------------------------
# ENSURE TARGET DIR
# --------------------------------------------------
if (-not (Test-Path $TargetDir)) {
    New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
}

# Create subfolders
@("functions","config","ui","runtime\logs","runtime\backups") | ForEach-Object {
    $sub = Join-Path $TargetDir $_
    if (-not (Test-Path $sub)) {
        New-Item -Path $sub -ItemType Directory -Force | Out-Null
    }
}

Write-Host "PMK Toolbox Bootstrap"
Write-Host "Install path: $TargetDir"
Write-Host ""

# --------------------------------------------------
# DETECT IF GIT PRESENT
# --------------------------------------------------
function Test-Git {
    try {
        git --version *> $null
        return $true
    } catch {
        return $false
    }
}

$UseGit = Test-Git

# --------------------------------------------------
# INSTALL OR UPDATE
# --------------------------------------------------
if ($UseGit) {
    Write-Host "Git detected, syncing repository..." -ForegroundColor Cyan

    if (Test-Path (Join-Path $TargetDir ".git")) {
        Push-Location $TargetDir
        git pull --rebase *> $null
        Pop-Location
    } else {
        git clone https://github.com/mkhai2589/toiuupc.git $TargetDir *> $null
    }
} else {
    Write-Host "Git not found – using RAW download" -ForegroundColor Yellow

    foreach ($relPath in $FilesToDownload) {
        $destFile = Join-Path $TargetDir $relPath
        $destDir  = Split-Path -Parent $destFile

        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }

        Download-File -RelativePath $relPath -Destination $destFile | Out-Null
    }
}

# --------------------------------------------------
# VERIFY MAIN SCRIPT
# --------------------------------------------------
if (-not (Test-Path $MainFile)) {
    Write-Host "`nError: ToiUuPC.ps1 not found!" -ForegroundColor Red
    exit 1
}

# --------------------------------------------------
# LAUNCH TOOL
# --------------------------------------------------
Write-Host "`nLaunching PMK Toolbox..." -ForegroundColor Green

Set-Location $TargetDir

powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $MainFile
