# ==================================================
# bootstrap.ps1 - BOOTSTRAP SCRIPT (FINAL VERSION)
# ==================================================
# Author: Minh Khai
# Version: 2.0.0
# Description: Download and install PMK Toolbox
# ==================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"

# Thiết lập encoding
try {
    chcp 65001 | Out-Null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# ==================================================
# LOGGING SYSTEM
# ==================================================
$LogFile = Join-Path $env:TEMP "toiuupc_bootstrap_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    } catch {}
    
    switch ($Level) {
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "WARN"  { Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
        "INFO"  { Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
        default { Write-Host "[$Level] $Message" -ForegroundColor White }
    }
}

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
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
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
        Write-Host ""
        Read-Host "Nhan Enter de thoat"
        exit 1
    }
}

function Test-InternetConnection {
    try {
        $response = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction Stop
        return $response
    } catch {
        return $false
    }
}

function Initialize-WorkingDirectory {
    param([string]$Path)
    
    try {
        Write-Log "Creating working directory: $Path" -Level "INFO"
        
        # Xoa thu muc cu neu ton tai
        if (Test-Path $Path) {
            Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Removed old directory" -Level "INFO"
        }
        
        # Tao thu muc moi
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        New-Item -ItemType Directory -Path "$Path\config" -Force | Out-Null
        New-Item -ItemType Directory -Path "$Path\functions" -Force | Out-Null
        New-Item -ItemType Directory -Path "$Path\runtime" -Force | Out-Null
        
        Write-Log "Directory created successfully" -Level "INFO"
        return $true
    } catch {
        Write-Log "Failed to create directory: $_" -Level "ERROR"
        return $false
    }
}

function Download-Project {
    param([string]$ZipUrl, [string]$TargetDir)
    
    $tempZip = Join-Path $env:TEMP "toiuupc_temp.zip"
    $extractDir = Join-Path $env:TEMP "toiuupc_extract"
    
    try {
        # Clean up
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
        
        # Download
        Write-Log "Downloading project from GitHub..." -Level "INFO"
        Invoke-WebRequest -Uri $ZipUrl -OutFile $tempZip -UseBasicParsing -ErrorAction Stop
        
        # Extract
        Write-Log "Extracting files..." -Level "INFO"
        Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force -ErrorAction Stop
        
        # Tim thu muc chinh
        $mainExtractedDir = Get-ChildItem $extractDir -Directory -Filter "toiuupc*" | Select-Object -First 1
        
        if ($mainExtractedDir) {
            Write-Log "Found project directory: $($mainExtractedDir.FullName)" -Level "INFO"
            
            # Copy tat ca file va thu muc
            Copy-Item "$($mainExtractedDir.FullName)\*" $TargetDir -Recurse -Force
            Write-Log "Files copied successfully" -Level "INFO"
            return $true
        } else {
            Write-Log "Could not find project directory in extracted files" -Level "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Download error: $_" -Level "ERROR"
        return $false
    } finally {
        # Cleanup
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Test-ProjectFiles {
    param([string]$BasePath)
    
    $requiredFiles = @(
        "ToiUuPC.ps1",
        "functions\utils.ps1",
        "config\applications.json",
        "config\dns.json",
        "config\tweaks.json"
    )
    
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $BasePath $file
        if (-not (Test-Path $fullPath)) {
            Write-Log "Missing file: $file" -Level "ERROR"
            return $false
        }
    }
    
    return $true
}

# ==================================================
# MAIN EXECUTION
# ==================================================
try {
    Show-BootstrapHeader
    
    # Kiem tra admin
    Write-Log "Checking administrator rights..." -Level "INFO"
    if (-not (Test-IsAdmin)) {
        Write-Log "Not running as administrator, restarting..." -Level "WARN"
        Relaunch-AsAdmin
    }
    
    Write-Host "[INFO] Administrator: OK" -ForegroundColor Green
    
    # Kiem tra internet
    Write-Log "Checking internet connection..." -Level "INFO"
    if (-not (Test-InternetConnection)) {
        Write-Host "[WARNING] No internet connection detected!" -ForegroundColor Yellow
        Write-Host "The download may fail. Continue anyway?" -ForegroundColor Yellow
        $choice = Read-Host "(Y/N)"
        if ($choice -ne 'Y' -and $choice -ne 'y') {
            exit 1
        }
    } else {
        Write-Host "[INFO] Internet connection: OK" -ForegroundColor Green
    }
    
    # Tao thu muc
    Write-Host "[INFO] Creating working directory: $BaseDir" -ForegroundColor Cyan
    if (-not (Initialize-WorkingDirectory -Path $BaseDir)) {
        Write-Host "[ERROR] Failed to create directory!" -ForegroundColor Red
        Write-Host "Press Enter to exit..." -ForegroundColor Yellow
        Read-Host | Out-Null
        exit 1
    }
    
    Write-Host "[INFO] Directory created successfully" -ForegroundColor Green
    
    # Tai du an
    Write-Host "[INFO] Downloading project from GitHub..." -ForegroundColor Cyan
    if (-not (Download-Project -ZipUrl $ZipUrl -TargetDir $BaseDir)) {
        Write-Host "[ERROR] Failed to download project!" -ForegroundColor Red
        Write-Host "Press Enter to exit..." -ForegroundColor Yellow
        Read-Host | Out-Null
        exit 1
    }
    
    Write-Host "[INFO] Project downloaded successfully" -ForegroundColor Green
    
    # Kiem tra file
    Write-Host "[INFO] Verifying project files..." -ForegroundColor Cyan
    if (-not (Test-ProjectFiles -BasePath $BaseDir)) {
        Write-Host "[ERROR] Project files are incomplete!" -ForegroundColor Red
        Write-Host "Press Enter to exit..." -ForegroundColor Yellow
        Read-Host | Out-Null
        exit 1
    }
    
    Write-Host "[INFO] All files verified" -ForegroundColor Green
    
    # Chay chuong trinh chinh
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "     LAUNCHING PMK TOOLBOX              " -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    Set-Location $BaseDir
    
    if (Test-Path $MainFile) {
        # Chay chuong trinh chinh
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MainFile
    } else {
        Write-Host "[ERROR] Main file not found: $MainFile" -ForegroundColor Red
    }
    
} catch {
    Write-Host "[FATAL ERROR] An unexpected error occurred: $_" -ForegroundColor Red
    Write-Host "Log file: $LogFile" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Bootstrap completed." -ForegroundColor Green
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host | Out-Null
