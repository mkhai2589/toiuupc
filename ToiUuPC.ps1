# ==========================================================
# ToiUuPC.ps1 - MAIN SCRIPT (FINAL VERSION)
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
    Write-Host "[ERROR] Không tìm thấy utils.ps1" -ForegroundColor Red
    exit 1
}
. $utilsPath

# ==========================================================
# ENSURE ADMINISTRATOR RIGHTS
# ==========================================================
Ensure-Admin

# ==========================================================
# LOAD ALL FUNCTION MODULES
# ==========================================================
$functions = @(
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1", 
    "dns-management.ps1",
    "clean-system.ps1"
)

foreach ($func in $functions) {
    $path = Join-Path $PSScriptRoot "functions\$func"
    if (Test-Path $path) {
        try {
            . $path
            Write-Status "Loaded: $func" -Type 'INFO'
        } catch {
            Write-Status "Error loading $func : $_" -Type 'ERROR'
        }
    } else {
        Write-Status "Missing: $func" -Type 'WARNING'
    }
}

# ==========================================================
# LOAD CONFIGURATIONS
# ==========================================================
$ConfigDir = Join-Path $PSScriptRoot "config"
$global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
$global:AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
$global:DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")

if (-not $global:TweaksConfig) {
    Write-Status "Tải cấu hình tweaks.json thất bại!" -Type 'ERROR'
}
if (-not $global:AppsConfig) {
    Write-Status "Tải cấu hình applications.json thất bại!" -Type 'ERROR'
}
if (-not $global:DnsConfig) {
    Write-Status "Tải cấu hình dns.json thất bại!" -Type 'ERROR'
}

# ==========================================================
# MAIN MENU DEFINITION
# ==========================================================
$MainMenuItems = @(
    @{ Key = "1"; Text = "Windows Tweaks (Tối ưu hệ thống)" }
    @{ Key = "2"; Text = "DNS Management (Quản lý DNS)" }
    @{ Key = "3"; Text = "Clean System (Dọn dẹp hệ thống)" }
    @{ Key = "4"; Text = "Install Applications (Cài đặt ứng dụng)" }
    @{ Key = "5"; Text = "Reload Configuration (Tải lại cấu hình)" }
    @{ Key = "0"; Text = "Thoát ToiUuPC" }
)

# ==========================================================
# MAIN PROGRAM LOOP
# ==========================================================
while ($true) {
    Show-Menu -MenuItems $MainMenuItems -Title "PMK TOOLBOX - MAIN MENU"
    
    $choice = Read-Host
    
    switch ($choice) {
        '1' {
            # Windows Tweaks
            if ($global:TweaksConfig) {
                Show-TweaksMenu -Config $global:TweaksConfig
            } else {
                Write-Status "Cấu hình tweaks chưa được tải!" -Type 'ERROR'
                Pause
            }
        }
        '2' {
            # DNS Management  
            if ($global:DnsConfig) {
                Show-DnsMenu -Config $global:DnsConfig
            } else {
                Write-Status "Cấu hình DNS chưa được tải!" -Type 'ERROR'
                Pause
            }
        }
        '3' {
            # Clean System
            Show-CleanSystem
        }
        '4' {
            # Install Applications
            if ($global:AppsConfig) {
                Show-AppsMenu -Config $global:AppsConfig
            } else {
                Write-Status "Cấu hình ứng dụng chưa được tải!" -Type 'ERROR'
                Pause
            }
        }
        '5' {
            # Reload Configuration
            Show-Header -Title "RELOAD CONFIGURATION"
            Write-Status "Đang tải lại cấu hình..." -Type 'INFO'
            
            $global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
            $global:AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
            $global:DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
            
            if ($global:TweaksConfig -and $global:AppsConfig -and $global:DnsConfig) {
                Write-Status "Tải lại cấu hình thành công!" -Type 'SUCCESS'
            } else {
                Write-Status "Có lỗi khi tải lại cấu hình!" -Type 'ERROR'
            }
            Pause
        }
        '0' {
            # Exit program
            Show-Header -Title "THOÁT CHƯƠNG TRÌNH"
            Write-Status "Cảm ơn bạn đã sử dụng ToiUuPC!" -Type 'INFO'
            Write-Host "Chương trình sẽ đóng trong 2 giây..." -ForegroundColor $global:UI_Colors.Warning
            Start-Sleep -Seconds 2
            exit 0
        }
        default {
            Write-Status "Lựa chọn không hợp lệ!" -Type 'WARNING'
            Pause
        }
    }
}
