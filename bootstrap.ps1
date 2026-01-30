# ==================================================
# bootstrap.ps1
# PMK TOOLBOX – ToiUuPC Bootstrap (FINAL)
# Author: Minh Khai
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
$BaseDir   = Join-Path $env:TEMP "ToiUuPC"
$MainFile  = Join-Path $BaseDir "ToiUuPC.ps1"

# ==================================================
# FUNCTIONS
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

function Relaunch-AsAdmin {
    Write-Host "Relaunching as Administrator..." -ForegroundColor Yellow

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"irm $($MyInvocation.MyCommand.Source) | iex`""
    $psi.Verb = "runas"

    [System.Diagnostics.Process]::Start($psi) | Out-Null
    exit
}

function Test-Git {
    try {
        git --version *> $null
        return $true
    } catch {
        return $false
    }
}

function Clean-Folder {
    param([string]$Path)

    if (Test-Path $Path) {
        Write-Host "Cleaning folder: $Path" -ForegroundColor DarkYellow
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Write-Step {
    param([string]$Text)

    Write-Host ""
    Write-Host "==> $Text" -ForegroundColor Cyan
}

# ==================================================
# ADMIN CHECK
# ==================================================
if (-not (Test-IsAdmin)) {
    Relaunch-AsAdmin
}

# ==================================================
# START
# ==================================================
Clear-Host
Write-Host "PMK TOOLBOX – ToiUuPC Bootstrap" -ForegroundColor Green
Write-Host "Author: Minh Khai"
Write-Host "Target: $BaseDir"
Write-Host ""

# ==================================================
# PREPARE FOLDER
# ==================================================
Write-Step "Prepare working directory"
Clean-Folder $BaseDir

# ==================================================
# INSTALL / UPDATE
# ==================================================
if (Test-Git) {

    Write-Step "Git detected – cloning repository"
    git clone $RepoUrl $BaseDir

}
else {

    Write-Step "Git not found – downloading ZIP"

    $zipFile = Join-Path $env:TEMP "toiuupc.zip"
    $extract = Join-Path $env:TEMP "toiuupc_extract"

    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }

    Write-Host "Downloading ZIP..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $ZipUrl -OutFile $zipFile -UseBasicParsing

    Write-Host "Extracting..." -ForegroundColor Gray
    Expand-Archive -Path $zipFile -DestinationPath $extract -Force

    $src = Get-ChildItem $extract | Select-Object -First 1
    Copy-Item "$($src.FullName)\*" $BaseDir -Recurse -Force
}

# ==================================================
# VERIFY STRUCTURE
# ==================================================
Write-Step "Verify project structure"

$required = @(
    "ToiUuPC.ps1",
    "functions\utils.ps1",
    "functions\tweaks.ps1",
    "functions\install-apps.ps1",
    "functions\dns-management.ps1",
    "functions\clean-system.ps1",
    "config\applications.json",
    "config\dns.json",
    "config\tweaks.json"
)

$missing = @()

foreach ($file in $required) {
    if (-not (Test-Path (Join-Path $BaseDir $file))) {
        $missing += $file
    }
}

if ($missing.Count -gt 0) {
    Write-Host "ERROR: Missing files:" -ForegroundColor Red
    $missing | ForEach-Object {
        Write-Host " - $_" -ForegroundColor Red
    }
    exit 1
}

Write-Host "All required files verified." -ForegroundColor Green

# ==================================================
# LAUNCH MAIN TOOL
# ==================================================
Write-Step "Launching PMK Toolbox"

Set-Location $BaseDir

powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $MainFile
