# ToiUuPC.ps1 - Phiên bản đơn giản hóa, không cột Action, menu số 1-5
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Off
$ErrorActionPreference = 'SilentlyContinue'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load core utils
$utilsPath = Join-Path $ScriptRoot "functions\utils.ps1"
if (-not (Test-Path $utilsPath)) {
    Write-Host "ERROR: functions\utils.ps1 not found" -ForegroundColor Red
    exit 1
}
. $utilsPath
Ensure-Admin

# Load function modules
$FunctionFiles = @(
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1",
    "dns-management.ps1",
    "clean-system.ps1"
)
foreach ($file in $FunctionFiles) {
    $path = Join-Path $ScriptRoot "functions\$file"
    if (-not (Test-Path $path)) {
        Write-Host "WARNING: Missing $file" -ForegroundColor Yellow
    } else {
        . $path
    }
}

# Load JSON config
$ConfigDir = Join-Path $ScriptRoot "config"
$TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
$AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
$DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
if (-not $TweaksConfig -or -not $AppsConfig -or -not $DnsConfig) {
    Write-Host "ERROR: Failed to load JSON config" -ForegroundColor Red
    exit 1
}

# Hiển thị logo
Show-PMKLogo

# Menu chính
while ($true) {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "          TOI UU PC - MAIN MENU           " -ForegroundColor White
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Windows Tweaks"
    Write-Host "  2. DNS Management"
    Write-Host "  3. Clean System"
    Write-Host "  4. Install Applications"
    Write-Host "  5. Reload Config"
    Write-Host ""
    Write-Host "  0. Exit"
    Write-Host ""
    $choice = Read-Host "Select (0-5)"
    switch ($choice) {
        '1' {
            Clear-Host
            if (Get-Command Invoke-TweaksMenu -ErrorAction SilentlyContinue) {
                Invoke-TweaksMenu -Config $TweaksConfig
            } else {
                Write-Host "Error: Invoke-TweaksMenu not found. Check tweaks.ps1" -ForegroundColor Red
                Read-Host "Press Enter"
            }
        }
        '2' {
            Clear-Host
            Invoke-DnsMenu
        }
        '3' {
            Clear-Host
            Invoke-CleanSystem
        }
        '4' {
            Clear-Host
            Invoke-AppMenu -Config $AppsConfig
        }
        '5' {
            Clear-Host
            $TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
            $AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
            $DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
            Write-Host "Configuration reloaded." -ForegroundColor Green
            Read-Host "Press Enter"
        }
        '0' {
            Write-Host "Exiting..." -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "Invalid selection." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
