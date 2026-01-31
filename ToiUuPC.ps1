# ==========================================================
# ToiUuPC.ps1 - MAIN SCRIPT (OFFICIAL FINAL VERSION)
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
# LOAD ALL FUNCTION MODULES (ULTRA ROBUST VERSION)
# ==========================================================
$functions = @(
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1", 
    "dns-management.ps1",
    "clean-system.ps1"
)

$global:loadedModules = @()
$global:failedModules = @()

Write-Host ""
Write-Host "=== LOADING MODULES ===" -ForegroundColor Cyan

foreach ($func in $functions) {
    $path = Join-Path $PSScriptRoot "functions\$func"
    if (Test-Path $path) {
        try {
            Write-Host "  Loading $func..." -ForegroundColor Gray -NoNewline
            
            # Load file
            . $path
            
            # Kiểm tra xem module có export functions không
            $moduleFunctions = Get-Command -Module (Get-Module) | Where-Object { $_.Source -like "*$func*" }
            
            if ($moduleFunctions.Count -gt 0) {
                $global:loadedModules += $func
                Write-Host " [OK]" -ForegroundColor Green
            } else {
                $global:failedModules += $func
                Write-Host " [NO FUNCTIONS]" -ForegroundColor Yellow
            }
        } catch {
            $global:failedModules += $func
            Write-Host " [ERROR]" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor DarkRed
        }
    } else {
        Write-Host "  Missing: $func" -ForegroundColor Yellow
        $global:failedModules += $func
    }
}

# Hiển thị báo cáo load modules
Write-Host ""
Write-Host "=== MODULE LOAD REPORT ===" -ForegroundColor Cyan
Write-Host "  Success: $($global:loadedModules.Count)/$($functions.Count)" -ForegroundColor $(if ($global:loadedModules.Count -eq $functions.Count) { "Green" } else { "Yellow" })

if ($global:failedModules.Count -gt 0) {
    Write-Host "  Failed: $($global:failedModules.Count)" -ForegroundColor Red
    foreach ($module in $global:failedModules) {
        Write-Host "    - $module" -ForegroundColor Yellow
    }
}

# Kiểm tra nếu không có module nào load được
if ($global:loadedModules.Count -eq 0) {
    Write-Host ""
    Write-Host "[ERROR] Khong load duoc module nao! Chuong trinh se dong." -ForegroundColor Red
    Write-Host "Hay chay bootstrap.ps1 de tai lai du an." -ForegroundColor Yellow
    Pause
    exit 1
}

Write-Host ""
Pause

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
            if ("tweaks.ps1" -in $global:loadedModules) {
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
            if ("dns-management.ps1" -in $global:loadedModules) {
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
            if ("clean-system.ps1" -in $global:loadedModules) {
                Show-CleanSystem
            } else {
                Write-Status "Module clean system chua duoc load! Vui long kiem tra lai." -Type 'ERROR'
                Pause
            }
        }
        '4' {
            if ("install-apps.ps1" -in $global:loadedModules) {
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
