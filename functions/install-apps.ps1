# ============================================================
# PMK TOOLBOX - INSTALL APPLICATIONS
# Author : Minh Khai
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

$Script:AppConfigPath = Join-Path $PSScriptRoot "..\config\applications.json"

# ------------------------------------------------------------
function Load-ApplicationConfig {
    if (-not (Test-Path $Script:AppConfigPath)) {
        Write-Host "ERROR: applications.json not found!" -ForegroundColor Red
        return $null
    }
    try {
        return Get-Content $Script:AppConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "ERROR: Invalid JSON format!" -ForegroundColor Red
        return $null
    }
}

# ------------------------------------------------------------
function Is-AppInstalled {
    param([string]$PackageId)
    try {
        return (winget list --id $PackageId 2>$null) -match $PackageId
    } catch { return $false }
}

# ------------------------------------------------------------
function Install-Application {
    param([object]$App)

    if (Is-AppInstalled $App.packageId) {
        Write-Host "[SKIP] $($App.name) already installed" -ForegroundColor Yellow
        return
    }

    Write-Host "[INSTALL] $($App.name)" -ForegroundColor Cyan

    $args = @(
        "install",
        "--id", $App.packageId,
        "--source", $App.source,
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    if ($App.silent) { $args += "--silent" }

    Start-Process winget -ArgumentList $args -Wait -NoNewWindow
}

# ------------------------------------------------------------
function Show-ApplicationsByCategory {
    param([object]$Config)

    Clear-Host
    Write-Host "INSTALL APPLICATIONS" -ForegroundColor Cyan
    Write-Host "---------------------------------------------"

    $index = 1
    $map = @{}

    foreach ($cat in $Config.categories) {
        Write-Host "`n[$cat]" -ForegroundColor Green
        $apps = $Config.applications | Where-Object category -eq $cat

        foreach ($app in $apps) {
            $key = "{0:00}" -f $index
            Write-Host " $key. $($app.name)"
            $map[$key] = $app
            $index++
        }
    }

    Write-Host "`n[00] Back"
    return $map
}

# ------------------------------------------------------------
function Invoke-AppMenu {
    param($Config)

    if (-not $Config) {
        $Config = Load-ApplicationConfig
        if (-not $Config) { return }
    }

    while ($true) {
        $map = Show-ApplicationsByCategory $Config
        $choice = Read-Host "Select"

        if ($choice -eq "00") { return }

        if ($map.ContainsKey($choice)) {
            Install-Application $map[$choice]
            Read-Host "Press Enter"
        }
    }
}
