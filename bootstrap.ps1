# ==================================================
# bootstrap.ps1
# PMK Toolbox – ToiUuPC Bootstrap (CLEAN VERSION)
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ==================================================
# CONFIG
# ==================================================
$RepoUrl   = "https://github.com/mkhai2589/toiuupc"
$ZipUrl    = "https://github.com/mkhai2589/toiuupc/archive/refs/heads/main.zip"
$TargetDir = Join-Path $env:TEMP "ToiUuPC"
$MainFile  = Join-Path $TargetDir "ToiUuPC.ps1"

# ==================================================
# ADMIN CHECK
# ==================================================
function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p  = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

if (-not (Test-IsAdmin)) {
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    exit 1
}

# ==================================================
# GIT CHECK
# ==================================================
function Test-Git {
    try {
        git --version *> $null
        return $true
    } catch {
        return $false
    }
}

# ==================================================
# PREPARE FOLDER
# ==================================================
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

Write-Host "PMK Toolbox Bootstrap"
Write-Host "Install path: $TargetDir"
Write-Host ""

# ==================================================
# INSTALL / UPDATE
# ==================================================
if (Test-Git) {

    Write-Host "Git detected – syncing repository..." -ForegroundColor Cyan

    if (Test-Path (Join-Path $TargetDir ".git")) {
        Push-Location $TargetDir
        git pull --rebase
        Pop-Location
    }
    else {
        git clone $RepoUrl $TargetDir
    }

}
else {

    Write-Host "Git not found – downloading ZIP..." -ForegroundColor Yellow

    $zipFile = Join-Path $env:TEMP "toiuupc.zip"
    $extract = Join-Path $env:TEMP "toiuupc_extract"

    if (Test-Path $zipFile)  { Remove-Item $zipFile  -Force }
    if (Test-Path $extract)  { Remove-Item $extract  -Recurse -Force }

    Invoke-WebRequest -Uri $ZipUrl -OutFile $zipFile -UseBasicParsing
    Expand-Archive -Path $zipFile -DestinationPath $extract -Force

    $src = Get-ChildItem $extract | Select-Object -First 1
    Copy-Item "$($src.FullName)\*" $TargetDir -Recurse -Force
}

# ==================================================
# VERIFY MAIN SCRIPT
# ==================================================
if (-not (Test-Path $MainFile)) {
    Write-Host "ERROR: ToiUuPC.ps1 not found!" -ForegroundColor Red
    exit 1
}

# ==================================================
# LAUNCH
# ==================================================
Write-Host ""
Write-Host "Launching PMK Toolbox..." -ForegroundColor Green
Set-Location $TargetDir

powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $MainFile
