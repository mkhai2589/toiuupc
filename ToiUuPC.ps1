# ==========================================================
# ToiUuPC.ps1 - MAIN SCRIPT
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
} catch {}

$utilsPath = Join-Path $PSScriptRoot "functions\utils.ps1"
if (-not (Test-Path $utilsPath)) {
    Write-Host "[ERROR] Khong tim thay utils.ps1" -ForegroundColor Red
    exit 1
}

try {
    . $utilsPath
} catch {
    Write-Host "[ERROR] Khong the load utils.ps1" -ForegroundColor Red
    exit 1
}

Ensure-Admin

Write-Status "Loading modules..." -Type 'INFO'

$modules = @(
    "tweaks.ps1",
    "install-apps.ps1",
    "dns-management.ps1",
    "clean-system.ps1"
)

foreach ($module in $modules) {
    $path = Join-Path $PSScriptRoot "functions\$module"
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

$ConfigDir = Join-Path $PSScriptRoot "config"
$global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
$global:AppsConfig = Load-JsonFile (Join-Path $ConfigDir "applications.json")
$global:DnsConfig = Load-JsonFile (Join-Path $ConfigDir "dns.json")

while ($true) {
    Show-MainMenu
    $choice = Read-Host
    
    switch ($choice) {
        '01' {
            if ($global:TweaksConfig) {
                Show-TweaksMenu -Config $global:TweaksConfig
            } else {
                Write-Status "Cau hinh tweaks chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '02' {
            if ($global:DnsConfig) {
                Show-DnsMenu -Config $global:DnsConfig
            } else {
                Write-Status "Cau hinh DNS chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '03' {
            Show-CleanSystem
        }
        '04' {
            if (Get-Command -Name "Checkpoint-Computer" -ErrorAction SilentlyContinue) {
                Show-Header -Title "TAO DIEM PHUC HOI"
                Write-Status "Dang tao diem phuc hoi..." -Type 'INFO'
                try {
                    Checkpoint-Computer -Description "PMK Toolbox Restore Point" -RestorePointType MODIFY_SETTINGS
                    Write-Status "Da tao diem phuc hoi thanh cong!" -Type 'SUCCESS'
                } catch {
                    Write-Status "Khong the tao diem phuc hoi!" -Type 'ERROR'
                }
                Pause
            } else {
                Write-Status "Chuc nang nay khong kha dung!" -Type 'ERROR'
                Pause
            }
        }
        '21' {
            Show-SystemInfo
        }
        '22' {
            Show-Performance
        }
        '51' {
            if ($global:AppsConfig) {
                Show-AppsMenu -Config $global:AppsConfig
            } else {
                Write-Status "Cau hinh ung dung chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '52' {
            Show-Header -Title "CAP NHAT WINGET"
            if (Test-WingetAvailable) {
                Write-Status "Winget da duoc cai dat!" -Type 'SUCCESS'
                Write-Host "   Chay 'winget upgrade --all' de cap nhat." -ForegroundColor Gray
            } else {
                Write-Status "Winget chua duoc cai dat!" -Type 'WARNING'
                $confirm = Read-Host "   Cai dat winget? (YES/NO): "
                if ($confirm -eq "YES") {
                    Install-WingetIfMissing
                }
            }
            Pause
        }
        '99' {
            Show-Changelog
        }
        '00' {
            Show-Header -Title "THOAT CHUONG TRINH"
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
