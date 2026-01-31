# ==================================================
# bootstrap.ps1 - BOOTSTRAP SCRIPT (FIXED WITH PAUSE ON ERROR)
# ==================================================

# SUPPRESS ERRORS FOR CLEAN START
$ErrorActionPreference = "Continue"  # Để hiển thị lỗi
$WarningPreference = "Continue"

# Thiết lập encoding
try {
    chcp 65001 | Out-Null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}
Set-StrictMode -Off

# ==================================================
# LOGGING SYSTEM (IMPROVED)
# ==================================================
$LogFile = Join-Path $env:TEMP "toiuupc_bootstrap_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$global:BootstrapDebug = $true  # Cho phép pause khi lỗi

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Nếu không ghi được log, không làm gì cả
    }
    
    # Hiển thị ra console với màu sắc
    switch ($Level) {
        "ERROR" { 
            Write-Host "[ERROR] $Message" -ForegroundColor Red 
            # Nếu đang debug, pause để đọc lỗi
            if ($global:BootstrapDebug) {
                Write-Host "Press any key to continue..." -ForegroundColor Yellow -NoNewline
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                Write-Host ""
            }
        }
        "WARN"  { Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
        "INFO"  { Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
        "DEBUG" { Write-Host "[DEBUG] $Message" -ForegroundColor Gray }
        default { Write-Host "[$Level] $Message" -ForegroundColor White }
    }
}

# Ghi thông tin bắt đầu
Write-Log "=== BAT DAU BOOTSTRAP TOIUUPC ==="
Write-Log "Thoi gian: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "User: $env:USERNAME"
Write-Log "May tinh: $env:COMPUTERNAME"
Write-Log "PS Version: $($PSVersionTable.PSVersion)"
Write-Log "Log file: $LogFile"
Write-Log "Debug mode: $global:BootstrapDebug"

# ==================================================
# CONFIGURATION
# ==================================================
$RepoUrl   = "https://github.com/mkhai2589/toiuupc"
$ZipUrl    = "https://github.com/mkhai2589/toiuupc/archive/refs/heads/main.zip"
$BaseDir   = Join-Path $env:TEMP "ToiUuPC"
$MainFile  = Join-Path $BaseDir "ToiUuPC.ps1"

Write-Log "Cau hinh duong dan"
Write-Log "  BaseDir: $BaseDir"
Write-Log "  MainFile: $MainFile"
Write-Log "  RepoUrl: $RepoUrl"

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
    Write-Log "Kiem tra quyen Administrator" -Level "DEBUG"
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        $isAdmin = $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        Write-Log "Ket qua quyen Admin: $isAdmin"
        return $isAdmin
    } catch {
        Write-Log "Loi khi kiem tra quyen Admin: $_" -Level "ERROR"
        return $false
    }
}

function Relaunch-AsAdmin {
    Write-Log "Khoi dong lai voi quyen Admin" -Level "WARN"
    Write-Host "[!] Can quyen Administrator" -ForegroundColor Yellow
    Write-Host "Dang khoi dong lai voi quyen Admin..." -ForegroundColor Cyan
    
    $currentScript = $MyInvocation.MyCommand.Path
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$currentScript`""
    $psi.Verb = "runas"
    
    try {
        Write-Log "Chuan bi khoi dong voi quyen Admin" -Level "DEBUG"
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Write-Log "Da khoi dong lai voi quyen Admin" -Level "INFO"
        exit 0
    } catch {
        Write-Log "Khong the khoi dong voi quyen Admin: $_" -Level "ERROR"
        Write-Host "[ERROR] Khong the khoi dong voi quyen Admin!" -ForegroundColor Red
        Write-Host "Vui long chay PowerShell voi quyen Administrator." -ForegroundColor Yellow
        Write-Host "Log file: $LogFile" -ForegroundColor Gray
        Write-Host ""
        Read-Host "Nhan Enter de thoat"
        exit 1
    }
}

function Test-GitAvailable {
    Write-Log "Kiem tra Git co san" -Level "DEBUG"
    try {
        git --version *> $null
        Write-Log "Git co san" -Level "INFO"
        return $true
    } catch {
        Write-Log "Git khong co san" -Level "INFO"
        return $false
    }
}

function Test-InternetConnection {
    Write-Log "Kiem tra ket noi Internet" -Level "DEBUG"
    try {
        # Thử ping Google DNS
        $response = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction Stop
        if ($response) {
            Write-Log "Ket noi Internet: OK" -Level "INFO"
            return $true
        } else {
            Write-Log "Khong co ket noi Internet (ping that bai)" -Level "WARN"
            return $false
        }
    } catch {
        Write-Log "Khong the kiem tra ket noi Internet: $_" -Level "WARN"
        # Thu cach khac
        try {
            $test = Invoke-WebRequest -Uri "http://www.google.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            Write-Log "Ket noi Internet (qua Google): OK" -Level "INFO"
            return $true
        } catch {
            Write-Log "Khong co ket noi Internet" -Level "WARN"
            return $false
        }
    }
}

function Initialize-WorkingDirectory {
    param([string]$Path)
    
    Write-Log "Chuan bi thu muc lam viec: $Path" -Level "INFO"
    
    try {
        # Clean existing directory
        if (Test-Path $Path) {
            Write-Log "Thu muc da ton tai, dang xoa..." -Level "DEBUG"
            Remove-Item $Path -Recurse -Force -ErrorAction Stop
            Write-Log "Da xoa thu muc cu" -Level "INFO"
        }
        
        # Create fresh directory
        Write-Log "Dang tao thu muc moi..." -Level "DEBUG"
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        
        if (Test-Path $Path) {
            Write-Log "Tao thu muc thanh cong: $Path" -Level "INFO"
            return $true
        } else {
            Write-Log "Loi: Khong tao duoc thu muc $Path" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Loi khi tao thu muc: $_" -Level "ERROR"
        return $false
    }
}

function Clone-WithGit {
    param([string]$Url, [string]$TargetDir)
    
    Write-Log "Thu tai du lieu bang Git: $Url => $TargetDir" -Level "INFO"
    
    try {
        Write-Log "Dang clone repository..." -Level "DEBUG"
        $result = git clone $Url $TargetDir 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Git clone thanh cong!" -Level "INFO"
            return $true
        } else {
            Write-Log "Git clone that bai! Exit code: $LASTEXITCODE" -Level "ERROR"
            if ($result) {
                Write-Log "Chi tiet loi Git: $result" -Level "ERROR"
            }
            return $false
        }
    } catch {
        Write-Log "Loi khi chay Git: $_" -Level "ERROR"
        return $false
    }
}

function Download-WithZip {
    param([string]$ZipUrl, [string]$TargetDir)
    
    Write-Log "Thu tai du lieu bang ZIP: $ZipUrl => $TargetDir" -Level "INFO"
    
    $tempZip = Join-Path $env:TEMP "toiuupc_temp_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    $extractDir = Join-Path $env:TEMP "toiuupc_extract_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    Write-Log "Temp ZIP: $tempZip" -Level "DEBUG"
    Write-Log "Extract dir: $extractDir" -Level "DEBUG"
    
    try {
        # Clean up old temp files
        if (Test-Path $tempZip) { 
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue 
        }
        if (Test-Path $extractDir) { 
            Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue 
        }
        
        # Download ZIP
        Write-Log "Dang tai ZIP file..." -Level "INFO"
        try {
            Invoke-WebRequest -Uri $ZipUrl -OutFile $tempZip -UseBasicParsing -ErrorAction Stop
            Write-Log "Tai ZIP thanh cong" -Level "INFO"
        } catch {
            Write-Log "Loi khi tai ZIP: $_" -Level "ERROR"
            return $false
        }
        
        if (-not (Test-Path $tempZip)) {
            Write-Log "Loi: File ZIP khong duoc tao" -Level "ERROR"
            return $false
        }
        
        $zipSize = [math]::Round((Get-Item $tempZip).Length / 1MB, 2)
        Write-Log "Kich thuoc ZIP: $zipSize MB" -Level "INFO"
        
        # Extract ZIP
        Write-Log "Dang giai nen ZIP..." -Level "INFO"
        try {
            Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force -ErrorAction Stop
            Write-Log "Giai nen thanh cong" -Level "INFO"
        } catch {
            Write-Log "Loi khi giai nen ZIP: $_" -Level "ERROR"
            return $false
        }
        
        # Find and copy extracted content
        Write-Log "Tim thu muc chua file ToiUuPC.ps1..." -Level "DEBUG"
        $sourceFolder = $null
        $allFolders = Get-ChildItem $extractDir -Directory -Recurse | Where-Object { 
            Test-Path (Join-Path $_.FullName "ToiUuPC.ps1") 
        }
        
        if ($allFolders.Count -gt 0) {
            $sourceFolder = $allFolders[0]
            Write-Log "Tim thay thu muc nguon: $($sourceFolder.FullName)" -Level "INFO"
        } else {
            # Thu tim trong thu muc goc extract
            $sourceFolders = Get-ChildItem $extractDir -Directory
            if ($sourceFolders.Count -eq 1) {
                $sourceFolder = $sourceFolders[0]
                Write-Log "Su dung thu muc duy nhat: $($sourceFolder.FullName)" -Level "INFO"
            }
        }
        
        if ($sourceFolder) {
            Write-Log "Dang copy du lieu tu: $($sourceFolder.FullName) den: $TargetDir" -Level "DEBUG"
            Copy-Item "$($sourceFolder.FullName)\*" $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Copy du lieu thanh cong" -Level "INFO"
        } else {
            Write-Log "Khong tim thay thu muc nguon, thu copy tat ca..." -Level "WARN"
            Copy-Item "$extractDir\*" $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Cleanup
        Write-Log "Dang don dep file tam..." -Level "DEBUG"
        Remove-Item $tempZip, $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Don dep file tam thanh cong" -Level "INFO"
        
        return $true
    } catch {
        Write-Log "Loi tong hop trong Download-WithZip: $_" -Level "ERROR"
        return $false
    }
}

function Verify-ProjectStructure {
    param([string]$BasePath)
    
    Write-Log "Kiem tra cau truc du an tai: $BasePath" -Level "INFO"
    
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
            Write-Log "THIEU FILE: $file" -Level "ERROR"
        } else {
            Write-Log "OK: $file" -Level "DEBUG"
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-Log "Cau truc du an HOAN TOAN OK!" -Level "INFO"
        return $true
    } else {
        Write-Log "Thieu $($missingFiles.Count) file!" -Level "ERROR"
        Write-Log "Danh sach file thieu: $($missingFiles -join ', ')" -Level "ERROR"
        return $false
    }
}

function Show-FinalInstructions {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "     HUONG DAN SU DUNG                  " -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "1. Log file: $LogFile" -ForegroundColor Cyan
    Write-Host "   (Xem file nay neu co loi)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. De su dung thuong xuyen:" -ForegroundColor Cyan
    Write-Host "   Copy thu muc: $BaseDir" -ForegroundColor Gray
    Write-Host "   Den vi tri khac (vi du: C:\ToiUuPC)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Tao shortcut tren Desktop:" -ForegroundColor Cyan
    Write-Host "   - Chuot phai vao ToiUuPC.ps1" -ForegroundColor Gray
    Write-Host "   - Chon 'Send to' -> 'Desktop (create shortcut)'" -ForegroundColor Gray
    Write-Host ""
}

# ==================================================
# MAIN EXECUTION FLOW
# ==================================================
Write-Log "=== BAT DAU CHUYEN DONG CHINH ===" -Level "INFO"

try {
    Show-BootstrapHeader
    
    # Step 1: Check admin rights
    Write-Log "=== BUOC 1: KIEM TRA QUYEN ADMIN ===" -Level "INFO"
    if (-not (Test-IsAdmin)) {
        Write-Log "Khong co quyen Admin, khoi dong lai..." -Level "WARN"
        Relaunch-AsAdmin
    } else {
        Write-Log "Da co quyen Administrator" -Level "INFO"
    }
    
    # Step 2: Check internet connection
    Write-Log "=== BUOC 2: KIEM TRA INTERNET ===" -Level "INFO"
    if (-not (Test-InternetConnection)) {
        Write-Log "Canh bao: Khong co ket noi Internet!" -Level "WARN"
        Write-Host "[!] Canh bao: Khong co ket noi Internet!" -ForegroundColor Yellow
        Write-Host "    Chuong trinh co the that bai khi tai du lieu." -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "Ban co muon tiep tuc? (Y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") {
            Write-Log "Nguoi dung huy bo" -Level "INFO"
            Write-Host "Da huy!" -ForegroundColor Gray
            Read-Host "Nhan Enter de thoat"
            exit 1
        }
        Write-Log "Nguoi dung quyet dinh tiep tuc khong co Internet" -Level "INFO"
    }
    
    # Step 3: Initialize working directory
    Write-Log "=== BUOC 3: TAO THU MUC LAM VIEC ===" -Level "INFO"
    if (-not (Initialize-WorkingDirectory -Path $BaseDir)) {
        Write-Log "Loi khi tao thu muc lam viec!" -Level "ERROR"
        Write-Host "[ERROR] Loi khi tao thu muc lam viec!" -ForegroundColor Red
        Write-Host "Xem chi tiet trong log file: $LogFile" -ForegroundColor Gray
        Write-Host ""
        Read-Host "Nhan Enter de thoat"
        exit 1
    }
    
    # Step 4: Download source code
    Write-Log "=== BUOC 4: TAI MA NGUON ===" -Level "INFO"
    $downloadSuccess = $false
    
    if (Test-GitAvailable) {
        Write-Log "Git co san, thu tai bang Git..." -Level "INFO"
        $downloadSuccess = Clone-WithGit -Url $RepoUrl -TargetDir $BaseDir
    } else {
        Write-Log "Git khong co san, se tai bang ZIP" -Level "INFO"
    }
    
    if (-not $downloadSuccess) {
        Write-Log "Git that bai hoac khong co, thu tai bang ZIP..." -Level "INFO"
        $downloadSuccess = Download-WithZip -ZipUrl $ZipUrl -TargetDir $BaseDir
    }
    
    if (-not $downloadSuccess) {
        Write-Log "Loi: Khong the tai du lieu tu ca Git va ZIP!" -Level "ERROR"
        Write-Host "[ERROR] Khong the tai du lieu!" -ForegroundColor Red
        Write-Host "   Thu cac cach sau:" -ForegroundColor Yellow
        Write-Host "   1. Kiem tra ket noi Internet" -ForegroundColor Gray
        Write-Host "   2. Thu chay lai voi quyen Administrator" -ForegroundColor Gray
        Write-Host "   3. Tai thu cong tu GitHub: $RepoUrl" -ForegroundColor Gray
        Write-Host "   4. Xem log file: $LogFile" -ForegroundColor Gray
        Write-Host ""
        Read-Host "Nhan Enter de thoat"
        exit 1
    }
    
    # Step 5: Verify project structure
    Write-Log "=== BUOC 5: KIEM TRA CAU TRUC DU AN ===" -Level "INFO"
    if (-not (Verify-ProjectStructure -BasePath $BaseDir)) {
        Write-Log "Cau truc du an khong hop le!" -Level "ERROR"
        Write-Host "[ERROR] Cau truc du an khong hop le!" -ForegroundColor Red
        Write-Host "   Co the repository bi thay doi cau truc." -ForegroundColor Yellow
        Write-Host "   Vui long bao cao loi cho tac gia." -ForegroundColor Gray
        Write-Host "   Xem chi tiet trong log file: $LogFile" -ForegroundColor Gray
        Read-Host "Nhan Enter de thoat"
        exit 1
    }
    
    # Step 6: Show final instructions
    Show-FinalInstructions
    
    # Step 7: Launch main application
    Write-Log "=== BUOC 6: KHOI DONG UNG DUNG CHINH ===" -Level "INFO"
    Write-Host "[+] Khoi dong ToiUuPC..." -ForegroundColor Cyan
    Write-Host ""
    
    # Change to project directory
    Set-Location $BaseDir
    Write-Log "Da chuyen den thu muc: $BaseDir" -Level "DEBUG"
    
    # Kiem tra lai file chinh
    if (-not (Test-Path $MainFile)) {
        Write-Log "LOI NGHIEM TRONG: Khong tim thay file chinh $MainFile" -Level "ERROR"
        Write-Host "[ERROR] Khong tim thay file chinh: $MainFile" -ForegroundColor Red
        Write-Host "Xem log file: $LogFile" -ForegroundColor Gray
        Read-Host "Nhan Enter de thoat"
        exit 1
    }
    
    $fileSize = [math]::Round((Get-Item $MainFile).Length / 1KB, 2)
    Write-Log "File chinh: $MainFile ($fileSize KB)" -Level "INFO"
    Write-Host "   File: $MainFile" -ForegroundColor Gray
    Write-Host "   Dung luong: $fileSize KB" -ForegroundColor Gray
    Write-Host ""
    
    # Launch main application
    Write-Log "Bat dau chay ToiUuPC.ps1..." -Level "INFO"
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MainFile
        Write-Log "ToiUuPC da dong binh thuong" -Level "INFO"
    } catch {
        Write-Log "Loi khi chay ToiUuPC: $_" -Level "ERROR"
        Write-Host "[ERROR] Loi khi khoi dong: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "   Thu cach sau:" -ForegroundColor Yellow
        Write-Host "   1. Chuot phai vao ToiUuPC.ps1" -ForegroundColor Gray
        Write-Host "   2. Chon 'Run with PowerShell'" -ForegroundColor Gray
        Write-Host "   3. Xem log file: $LogFile" -ForegroundColor Gray
        Write-Host ""
        Read-Host "Nhan Enter de thoat"
    }
    
} catch {
    Write-Log "LOI KHONG XU LY DUOC TRONG QUA TRINH BOOTSTRAP: $_" -Level "ERROR"
    Write-Host "[ERROR CRITICAL] Co loi nghiem trong: $_" -ForegroundColor Red
    Write-Host "Vui long bao cao loi nay cho tac gia." -ForegroundColor Yellow
    Write-Host "Log file: $LogFile" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Nhan Enter de thoat"
    exit 1
}

# If we return here, the application has exited
Write-Log "=== KET THUC BOOTSTRAP ===" -Level "INFO"
Write-Host ""
Write-Host "ToiUuPC da dong." -ForegroundColor Gray
Write-Host "Log file: $LogFile" -ForegroundColor Gray
Start-Sleep -Seconds 3
