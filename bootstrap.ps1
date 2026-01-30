# ==================================================
# bootstrap.ps1
# PMK TOOLBOX – ToiUuPC Bootstrap (SIMPLE VERSION)
# Author: Minh Khai
# ==================================================

# Suppress errors and warnings during bootstrap
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
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
    Write-Host "Khoi dong lai voi quyen Administrator..." -ForegroundColor Yellow

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    # Sửa lỗi: dùng đường dẫn script hiện tại, không phải tải từ internet
    $scriptPath = $MyInvocation.MyCommand.Path
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $psi.Verb = "runas"

    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Write-Host "Ban da huy yeu cau chay voi quyen Administrator." -ForegroundColor Red
    }
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
        Write-Host "Dang xoa thu muc cu: $Path" -ForegroundColor DarkYellow
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
    # Nếu không thành công, chương trình đã thoát
    exit
}

# ==================================================
# START
# ==================================================
Clear-Host
Write-Host "PMK TOOLBOX – ToiUuPC Bootstrap" -ForegroundColor Green
Write-Host "Author: Minh Khai"
Write-Host "Thu muc: $BaseDir"
Write-Host ""

# ==================================================
# PREPARE FOLDER
# ==================================================
Write-Step "Chuan bi thu muc lam viec"
Clean-Folder $BaseDir

# ==================================================
# INSTALL / UPDATE
# ==================================================
if (Test-Git) {
    Write-Step "Phat hien Git – dang clone repository"
    git clone $RepoUrl $BaseDir 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Clone that bai. Thu phuong phap ZIP." -ForegroundColor Red
        $useGit = $false
    } else {
        $useGit = $true
    }
} else {
    $useGit = $false
}

if (-not $useGit) {
    Write-Step "Git khong co san – dang tai ZIP"

    $zipFile = Join-Path $env:TEMP "toiuupc.zip"
    $extract = Join-Path $env:TEMP "toiuupc_extract"

    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }

    Write-Host "Dang tai ZIP..." -ForegroundColor Gray
    try {
        Invoke-WebRequest -Uri $ZipUrl -OutFile $zipFile -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "Tai ZIP that bai: $_" -ForegroundColor Red
        exit 1
    }

    Write-Host "Dang giai nen..." -ForegroundColor Gray
    try {
        Expand-Archive -Path $zipFile -DestinationPath $extract -Force -ErrorAction Stop
    } catch {
        Write-Host "Giai nen ZIP that bai: $_" -ForegroundColor Red
        exit 1
    }

    $src = Get-ChildItem $extract | Select-Object -First 1
    if ($src) {
        Copy-Item "$($src.FullName)\*" $BaseDir -Recurse -Force
    } else {
        Write-Host "Khong tim thay noi dung trong file ZIP." -ForegroundColor Red
        exit 1
    }
}

# ==================================================
# VERIFY STRUCTURE
# ==================================================
Write-Step "Kiem tra cau truc du an"

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
    Write-Host "LOI: Thieu cac file sau:" -ForegroundColor Red
    $missing | ForEach-Object {
        Write-Host " - $_" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Tat ca file can thiet da san sang." -ForegroundColor Green

# ==================================================
# LAUNCH MAIN TOOL
# ==================================================
Write-Step "Khoi dong PMK Toolbox"

Set-Location $BaseDir

# Chạy main script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MainFile

# Khi main script thoát, chương trình kết thúc.
