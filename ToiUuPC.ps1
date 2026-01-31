Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
} catch {}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

$utilsPath = Join-Path $scriptPath "functions\utils.ps1"
if (-not (Test-Path $utilsPath)) {
    Write-Host "[ERROR] Khong tim thay utils.ps1" -ForegroundColor Red
    Read-Host "Nhan Enter de thoat"
    exit 1
}

. $utilsPath

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[ERROR] Vui long chay voi quyen Administrator!" -ForegroundColor Red
    Write-Host "Hay chuot phai vao file va chon 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Nhan Enter de thoat"
    exit 1
}

Write-Status "Dang tai module..." -Type 'INFO'

$modules = @(
    "tweaks.ps1",
    "install-apps.ps1",
    "dns-management.ps1",
    "clean-system.ps1"
)

foreach ($module in $modules) {
    $path = Join-Path $scriptPath "functions\$module"
    if (Test-Path $path) {
        try {
            . $path
            Write-Host "  [OK] $module" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] $module" -ForegroundColor Red
        }
    } else {
        Write-Host "  [MISSING] $module" -ForegroundColor Yellow
    }
}

$configDir = Join-Path $scriptPath "config"

$global:TweaksConfig = Load-JsonConfig (Join-Path $configDir "tweaks.json")
$global:AppsConfig = Load-JsonConfig (Join-Path $configDir "applications.json")
$global:DnsConfig = Load-JsonConfig (Join-Path $configDir "dns.json")

while ($true) {
    Show-Header -Title "PMK TOOLBOX"
    
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor Cyan
    Write-Host "|  TOI UU HE THONG          |  CAI DAT UNG DUNG        |" -ForegroundColor Cyan
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor Cyan
    Write-Host "| [1] Windows Tweaks        | [4] Install Applications |" -ForegroundColor Gray
    Write-Host "| [2] DNS Management        |                           |" -ForegroundColor Gray
    Write-Host "| [3] Clean System          |                           |" -ForegroundColor Gray
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor Cyan
    Write-Host "|  TIEN ICH                 |  THOAT                   |" -ForegroundColor Cyan
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor Cyan
    Write-Host "| [5] Reload Configuration  | [0] Thoat                |" -ForegroundColor Gray
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "Chon chuc nang (0-5): "
    
    switch ($choice) {
        '1' {
            if ($global:TweaksConfig) {
                Show-TweaksMenu -Config $global:TweaksConfig
            } else {
                Write-Status "Cau hinh tweaks chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '2' {
            if ($global:DnsConfig) {
                Show-DnsMenu -Config $global:DnsConfig
            } else {
                Write-Status "Cau hinh DNS chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '3' {
            Show-CleanSystem
        }
        '4' {
            if ($global:AppsConfig) {
                Show-AppsMenu -Config $global:AppsConfig
            } else {
                Write-Status "Cau hinh ung dung chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '5' {
            Show-Header -Title "TAI LAI CAU HINH"
            Write-Status "Dang tai lai cau hinh..." -Type 'INFO'
            
            $global:TweaksConfig = Load-JsonConfig (Join-Path $configDir "tweaks.json")
            $global:AppsConfig = Load-JsonConfig (Join-Path $configDir "applications.json")
            $global:DnsConfig = Load-JsonConfig (Join-Path $configDir "dns.json")
            
            if ($global:TweaksConfig -and $global:AppsConfig -and $global:DnsConfig) {
                Write-Status "Tai lai thanh cong!" -Type 'SUCCESS'
            } else {
                Write-Status "Co loi khi tai lai!" -Type 'ERROR'
            }
            Pause
        }
        '0' {
            Show-Header -Title "THOAT"
            Write-Status "Cam on ban da su dung PMK Toolbox!" -Type 'INFO'
            Start-Sleep -Seconds 2
            exit 0
        }
        default {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
