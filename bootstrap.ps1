# ==================================================
# bootstrap.ps1 - BOOTSTRAP SCRIPT (FINAL PRO)
# ==================================================

# SUPPRESS ERRORS FOR CLEAN START
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Off

# ==================================================
# CONFIGURATION
# ==================================================
$RepoUrl   = "https://github.com/mkhai2589/toiuupc"
$ZipUrl    = "https://github.com/mkhai2589/toiuupc/archive/refs/heads/main.zip"
$BaseDir   = Join-Path $env:TEMP "ToiUuPC"
$MainFile  = Join-Path $BaseDir "ToiUuPC.ps1"

# ==================================================
# CORE FUNCTIONS
# ==================================================
function Show-BootstrapHeader {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    PMK TOOLBOX - BOOTSTRAP             " -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Author: Minh Khai"
    Write-Host "Target: $BaseDir"
    Write-Host ""
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Relaunch-AsAdmin {
    Write-Host "[!] Can quyen Administrator" -ForegroundColor Yellow
    Write-Host "Dang khoi dong lai voi quyen Admin..." -ForegroundColor Cyan
    
    $currentScript = $MyInvocation.MyCommand.Path
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$currentScript`""
    $psi.Verb = "runas"
    
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        exit 0
    } catch {
        Write-Host "[ERROR] Khong the khoi dong voi quyen Admin!" -ForegroundColor Red
        Write-Host "Vui long chay PowerShell voi quyen Administrator." -ForegroundColor Yellow
        Read-Host "Nhan Enter de thoat"
        exit 1
    }
}

function Test-GitAvailable {
    try {
        git --version *> $null
        return $true
    } catch {
        return $false
    }
}

function Initialize-WorkingDirectory {
    param([string]$Path)
    
    Write-Host "[+] Chuan bi thu muc lam viec..." -ForegroundColor Cyan
    
    # Clean existing directory
    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Create fresh directory
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    
    if (Test-Path $Path) {
        Write-Host "   => Thu muc: $Path" -ForegroundColor Green
        return $true
    } else {
        Write-Host "   => Loi tao thu muc!" -ForegroundColor Red
        return $false
    }
}

function Clone-WithGit {
    param([string]$Url, [string]$TargetDir)
    
    Write-Host "[+] Tai du lieu bang Git..." -ForegroundColor Cyan
    
    try {
        git clone $Url $TargetDir 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   => Git clone thanh cong!" -ForegroundColor Green
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}

function Download-WithZip {
    param([string]$ZipUrl, [string]$TargetDir)
    
    Write-Host "[+] Tai du lieu bang ZIP..." -ForegroundColor Cyan
    
    $tempZip = Join-Path $env:TEMP "toiuupc_temp.zip"
    $extractDir = Join-Path $env:TEMP "toiuupc_extract"
    
    try {
        # Clean up old temp files
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
        
        # Download ZIP
        Write-Host "   => Dang tai ZIP..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $ZipUrl -OutFile $tempZip -UseBasicParsing
        
        # Extract ZIP
        Write-Host "   => Dang giai nen..." -ForegroundColor Gray
        Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force
        
        # Find and copy extracted content
        $sourceFolder = Get-ChildItem $extractDir | Select-Object -First 1
        if ($sourceFolder) {
            Copy-Item "$($sourceFolder.FullName)\*" $TargetDir -Recurse -Force
            Write-Host "   => Giai nen thanh cong!" -ForegroundColor Green
        } else {
            Write-Host "   => Loi: ZIP rong!" -ForegroundColor Red
            return $false
        }
        
        # Cleanup
        Remove-Item $tempZip, $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        Write-Host "   => Loi download: $_" -ForegroundColor Red
        return $false
    }
}

function Verify-ProjectStructure {
    param([string]$BasePath)
    
    Write-Host "[+] Kiem tra cau truc du an..." -ForegroundColor Cyan
    
    $requiredFiles = @(
        "ToiUuPC.ps1",
        "functions\utils.ps1",
        "functions\Show-PMKLogo.ps1",
        "functions\tweaks.ps1",
        "functions\install-apps.ps1",
        "functions\dns-management.ps1",
        "functions\clean-system.ps1",
        "config\applications.json",
        "config\dns.json",
        "config\tweaks.json"
    )
    
    $missingFiles = @()
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $BasePath $file
        if (-not (Test-Path $fullPath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-Host "   => Cau truc du an OK!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "   => Thieu cac file sau:" -ForegroundColor Red
        foreach ($file in $missingFiles) {
            Write-Host "      - $file" -ForegroundColor Red
        }
        return $false
    }
}

# ==================================================
# MAIN EXECUTION FLOW
# ==================================================
Show-BootstrapHeader

# Step 1: Check admin rights
if (-not (Test-IsAdmin)) {
    Relaunch-AsAdmin
}

# Step 2: Initialize working directory
if (-not (Initialize-WorkingDirectory -Path $BaseDir)) {
    Read-Host "Nhan Enter de thoat"
    exit 1
}

# Step 3: Download source code
$downloadSuccess = $false

if (Test-GitAvailable) {
    $downloadSuccess = Clone-WithGit -Url $RepoUrl -TargetDir $BaseDir
}

if (-not $downloadSuccess) {
    $downloadSuccess = Download-WithZip -ZipUrl $ZipUrl -TargetDir $BaseDir
}

if (-not $downloadSuccess) {
    Write-Host "[ERROR] Khong the tai du lieu!" -ForegroundColor Red
    Read-Host "Nhan Enter de thoat"
    exit 1
}

# Step 4: Verify project structure
if (-not (Verify-ProjectStructure -BasePath $BaseDir)) {
    Write-Host "[ERROR] Cau truc du an khong hop le!" -ForegroundColor Red
    Read-Host "Nhan Enter de thoat"
    exit 1
}

# Step 5: Launch main application
Write-Host "[+] Khoi dong ToiUuPC..." -ForegroundColor Cyan
Write-Host ""

# Change to project directory and launch
Set-Location $BaseDir

try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MainFile
} catch {
    Write-Host "[ERROR] Loi khi khoi dong: $_" -ForegroundColor Red
    Read-Host "Nhan Enter de thoat"
    exit 1
}

# If we return here, the application has exited
Write-Host ""
Write-Host "ToiUuPC da dong." -ForegroundColor Gray
Start-Sleep -Seconds 2
