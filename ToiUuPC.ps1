# ==========================================================
# ToiUuPC.ps1 - MAIN SCRIPT (FIXED FINAL)
# ==========================================================

# SUPPRESS ERRORS FOR CLEAN START
Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# ==========================================================
# SETUP ENVIRONMENT
# ==========================================================
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
} catch {
    # Ignore encoding errors
}

# ==========================================================
# LOAD CORE UTILITIES
# ==========================================================
$utilsPath = Join-Path $PSScriptRoot "functions\utils.ps1"
if (-not (Test-Path $utilsPath)) {
    Write-Host "[ERROR] Khong tim thay utils.ps1" -ForegroundColor Red
    Write-Host "Vui long chay bootstrap.ps1 de tai lai du an." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Nhan Enter de thoat"
    exit 1
}

# Load utils với xử lý lỗi
try {
    . $utilsPath
    Write-Status "Loaded utilities" -Type 'INFO'
} catch {
    Write-Host "[ERROR] Khong the load utils.ps1: $_" -ForegroundColor Red
    exit 1
}

# ==========================================================
# ENSURE ADMINISTRATOR RIGHTS
# ==========================================================
Ensure-Admin

# ==========================================================
# LOAD ALL FUNCTION MODULES (FIXED ERROR HANDLING)
# ==========================================================
$functions = @(
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1", 
    "dns-management.ps1",
    "clean-system.ps1"
)

$loadedModules = @()
$failedModules = @()

foreach ($func in $functions) {
    $path = Join-Path $PSScriptRoot "functions\$func"
    if (Test-Path $path) {
        try {
            # Kiểm tra cú pháp trước khi load
            $scriptContent = Get-Content $path -Raw -ErrorAction Stop
            $tokens = $null
            $parseErrors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$parseErrors)
            
            if ($parseErrors.Count -eq 0) {
                . $path
                $loadedModules += $func
                Write-Status "Loaded: $func" -Type 'INFO'
            } else {
                $failedModules += $func
                Write-Status "Syntax error in $func - skipping" -Type 'WARNING'
            }
        } catch {
            $failedModules += $func
            Write-Status "Error loading $func : $($_.Exception.Message)" -Type 'ERROR'
            # KHÔNG DỪNG CHƯƠNG TRÌNH, TIẾP TỤC VỚI MODULES KHÁC
        }
    } else {
        Write-Status "Missing: $func" -Type 'WARNING'
        $failedModules += $func
    }
}

# Hiển thị báo cáo load modules
Write-Host ""
Write-Host " BAO CAO LOAD MODULES:" -ForegroundColor Cyan
Write-Host "   Thanh cong: $($loadedModules.Count)/$($functions.Count) modules" -ForegroundColor $(if ($loadedModules.Count -eq $functions.Count) { "Green" } else { "Yellow" })
if ($failedModules.Count -gt 0) {
    Write-Host "   That bai: $($failedModules -join ', ')" -ForegroundColor Yellow
}
Write-Host ""

# ==========================================================
# LOAD CONFIGURATIONS
# ==========================================================
$ConfigDir = Join-Path $PSScriptRoot "config"
$global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
$global:AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
$global:DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")

if (-not $global:TweaksConfig) {
    Write-Status "Tai cau hinh tweaks.json that bai!" -Type 'ERROR'
}
if (-not $global:AppsConfig) {
    Write-Status "Tai cau hinh applications.json that bai!" -Type 'ERROR'
}
if (-not $global:DnsConfig) {
    Write-Status "Tai cau hinh dns.json that bai!" -Type 'ERROR'
}

# ==========================================================
# MAIN MENU DEFINITION
# ==========================================================
$MainMenuItems = @(
    @{ Key = "1"; Text = "Windows Tweaks (Toi uu he thong)" }
    @{ Key = "2"; Text = "DNS Management (Quan ly DNS)" }
    @{ Key = "3"; Text = "Clean System (Don dep he thong)" }
    @{ Key = "4"; Text = "Install Applications (Cai dat ung dung)" }
    @{ Key = "5"; Text = "Reload Configuration (Tai lai cau hinh)" }
    @{ Key = "0"; Text = "Thoat ToiUuPC" }
)

# ==========================================================
# MAIN PROGRAM LOOP
# ==========================================================
while ($true) {
    Show-Menu -MenuItems $MainMenuItems -Title "PMK TOOLBOX - MAIN MENU"
    
    $choice = Read-Host
    
    switch ($choice) {
        '1' {
            # Windows Tweaks - Kiểm tra module đã load
            if ("tweaks.ps1" -in $loadedModules) {
                if ($global:TweaksConfig) {
                    Show-TweaksMenu -Config $global:TweaksConfig
                } else {
                    Write-Status "Cau hinh tweaks chua duoc tai!" -Type 'ERROR'
                    Pause
                }
            } else {
                Write-Status "Module tweaks chua duoc load! Vui long kiem tra lai." -Type 'ERROR'
                Pause
            }
        }
        '2' {
            # DNS Management - Kiểm tra module đã load
            if ("dns-management.ps1" -in $loadedModules) {
                if ($global:DnsConfig) {
                    Show-DnsMenu -Config $global:DnsConfig
                } else {
                    Write-Status "Cau hinh DNS chua duoc tai!" -Type 'ERROR'
                    Pause
                }
            } else {
                Write-Status "Module DNS chua duoc load! Vui long kiem tra lai." -Type 'ERROR'
                Pause
            }
        }
        '3' {
            # Clean System - Kiểm tra module đã load
            if ("clean-system.ps1" -in $loadedModules) {
                Show-CleanSystem
            } else {
                Write-Status "Module clean system chua duoc load! Vui long kiem tra lai." -Type 'ERROR'
                Pause
            }
        }
        '4' {
            # Install Applications - Kiểm tra module đã load
            if ("install-apps.ps1" -in $loadedModules) {
                if ($global:AppsConfig) {
                    Show-AppsMenu -Config $global:AppsConfig
                } else {
                    Write-Status "Cau hinh ung dung chua duoc tai!" -Type 'ERROR'
                    Pause
                }
            } else {
                Write-Status "Module install apps chua duoc load! Vui long kiem tra lai." -Type 'ERROR'
                Pause
            }
        }
        '5' {
            # Reload Configuration
            Show-Header -Title "TAI LAI CAU HINH"
            Write-Status "Dang tai lai cau hinh..." -Type 'INFO'
            
            $global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
            $global:AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
            $global:DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
            
            if ($global:TweaksConfig -and $global:AppsConfig -and $global:DnsConfig) {
                Write-Status "Tai lai cau hinh thanh cong!" -Type 'SUCCESS'
            } else {
                Write-Status "Co loi khi tai lai cau hinh!" -Type 'ERROR'
            }
            Pause
        }
        '0' {
            # Exit program
            Show-Header -Title "THOAT CHUONG TRINH"
            Write-Status "Cam on ban da su dung ToiUuPC!" -Type 'INFO'
            Write-Host "Chuong trinh se dong trong 2 giay..." -ForegroundColor $global:UI_Colors.Warning
            Start-Sleep -Seconds 2
            exit 0
        }
        default {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
