# ==================================================
# bootstrap.ps1 - BOOTSTRAP SCRIPT (100% WORKING VERSION)
# ==================================================

# THIẾT LẬP RÕ RÀNG
$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"

# Thiết lập encoding
try {
    chcp 65001 | Out-Null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}
Set-StrictMode -Off

# ==================================================
# LOGGING SYSTEM (SIMPLE BUT EFFECTIVE)
# ==================================================
$LogFile = Join-Path $env:TEMP "toiuupc_bootstrap_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Ghi vào file
    try {
        Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    } catch {}
    
    # Hiển thị ra console với màu sắc
    switch ($Level) {
        "ERROR" { 
            Write-Host "[ERROR] $Message" -ForegroundColor Red 
            # PAUSE ĐỂ ĐỌC LỖI
            Write-Host "Press any key to continue..." -ForegroundColor Yellow -NoNewline
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            Write-Host ""
        }
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
    Write-Host "Log file: $LogFile"
    Write-Host ""
}

function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
        # Thử ping Google DNS
        $response = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction Stop
        return $response
    } catch {
        return $false
    }
}

function Initialize-WorkingDirectory {
    param([string]$Path)
    
    try {
        # Xóa thư mục cũ nếu tồn tại
        if (Test-Path $Path) {
            Remove-Item $Path -Recurse -Force -ErrorAction Stop
        }
        
        # Tạo thư mục mới
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Download-Project {
    param([string]$ZipUrl, [string]$TargetDir)
    
    $tempZip = Join-Path $env:TEMP "toiuupc_temp.zip"
    $extractDir = Join-Path $env:TEMP "toiuupc_extract"
    
    try {
        # Clean up
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
        
        # Download
        Write-Log "Downloading project from GitHub..." -Level "INFO"
        Invoke-WebRequest -Uri $ZipUrl -OutFile $tempZip -UseBasicParsing -ErrorAction Stop
        
        # Extract
        Write-Log "Extracting files..." -Level "INFO"
        Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force -ErrorAction Stop
        
        # Find and copy
        $foundDir = $null
        
        # Tìm thư mục chứa ToiUuPC.ps1
        $allDirs = Get-ChildItem $extractDir -Directory -Recurse | Where-Object { 
            Test-Path (Join-Path $_.FullName "ToiUuPC.ps1") 
        }
        
        if ($allDirs.Count -gt 0) {
            $foundDir = $allDirs[0].FullName
        } else {
            # Thử tìm trong thư mục đầu tiên
            $firstDir = Get-ChildItem $extractDir -Directory | Select-Object -First 1
            if ($firstDir) {
                $foundDir = $firstDir.FullName
            }
        }
        
        if ($foundDir) {
            Write-Log "Copying files from: $foundDir" -Level "INFO"
            Copy-Item "$foundDir\*" $TargetDir -Recurse -Force
            return $true
        } else {
            Write-Log "Could not find project files" -Level "ERROR"
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
        "functions\utils.ps1"
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
    
    # Kiểm tra admin
    Write-Log "Checking administrator rights..." -Level "INFO"
    if (-not (Test-IsAdmin)) {
        Write-Log "Not running as administrator, restarting..." -Level "WARN"
        Relaunch-AsAdmin
    }
    
    # Kiểm tra internet
    Write-Log "Checking internet connection..." -Level "INFO"
    if (-not (Test-InternetConnection)) {
        Write-Host "[WARNING] No internet connection detected!" -ForegroundColor Yellow
        Write-Host "The download may fail. Continue anyway?" -ForegroundColor Yellow
        $choice = Read-Host "(Y/N)"
        if ($choice -ne 'Y' -and $choice -ne 'y') {
            exit 1
        }
    }
    
    # Tạo thư mục
    Write-Log "Creating working directory: $BaseDir" -Level "INFO"
    if (-not (Initialize-WorkingDirectory -Path $BaseDir)) {
        Write-Log "Failed to create directory" -Level "ERROR"
        exit 1
    }
    
    # Tải dự án
    Write-Log "Downloading project..." -Level "INFO"
    if (-not (Download-Project -ZipUrl $ZipUrl -TargetDir $BaseDir)) {
        Write-Log "Failed to download project" -Level "ERROR"
        exit 1
    }
    
    # Kiểm tra file
    Write-Log "Verifying project files..." -Level "INFO"
    if (-not (Test-ProjectFiles -BasePath $BaseDir)) {
        Write-Log "Project files are incomplete" -Level "ERROR"
        exit 1
    }
    
    # Chạy chương trình chính
    Write-Log "Launching ToiUuPC..." -Level "INFO"
    Set-Location $BaseDir
    
    if (Test-Path $MainFile) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "     LAUNCHING PMK TOOLBOX              " -ForegroundColor White
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        # Chạy chương trình chính
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MainFile
    } else {
        Write-Log "Main file not found: $MainFile" -Level "ERROR"
        Write-Host "[ERROR] Main file not found!" -ForegroundColor Red
        Write-Host "Please check the project structure." -ForegroundColor Yellow
    }
    
} catch {
    Write-Log "Unhandled error: $_" -Level "ERROR"
    Write-Host "[FATAL ERROR] An unexpected error occurred." -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Red
    Write-Host "Log file: $LogFile" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Bootstrap completed." -ForegroundColor Green
Write-Host "Log file: $LogFile" -ForegroundColor Gray
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host | Out-Null
