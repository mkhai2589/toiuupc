# ============================================================
# PMK TOOLBOX - INSTALL APPLICATIONS
# Author : Minh Khai
# ============================================================

$Script:AppConfigPath = Join-Path $PSScriptRoot "..\config\applications.json"

# ------------------------------------------------------------
function Load-ApplicationConfig {
    if (-not (Test-Path $Script:AppConfigPath)) {
        Write-Host "ERROR: applications.json not found!" -ForegroundColor Red
        return $null
    }

    try {
        return Get-Content $Script:AppConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host "ERROR: Invalid JSON format!" -ForegroundColor Red
        return $null
    }
}

# ------------------------------------------------------------
function Is-AppInstalled {
    param (
        [string]$PackageId
    )

    try {
        $result = winget list --id $PackageId 2>$null
        return ($result -match $PackageId)
    }
    catch {
        return $false
    }
}

# ------------------------------------------------------------
function Install-Application {
    param (
        [object]$App
    )

    if (Is-AppInstalled $App.packageId) {
        Write-Host ("[SKIP] {0} already installed" -f $App.name) -ForegroundColor Yellow
        return
    }

    Write-Host ("[INSTALL] {0}" -f $App.name) -ForegroundColor Cyan

    $args = @(
        "install",
        "--id", $App.packageId,
        "--source", $App.source,
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    if ($App.silent -eq $true) {
        $args += "--silent"
    }

    Start-Process -FilePath "winget" -ArgumentList $args -Wait -NoNewWindow
}

# ------------------------------------------------------------
function Show-ApplicationsByCategory {
    param (
        [object]$Config
    )

    Clear-Host
    Write-Host "+======================================================+" -ForegroundColor DarkGray
    Write-Host "| INSTALL APPLICATIONS                                  |" -ForegroundColor White
    Write-Host "+======================================================+" -ForegroundColor DarkGray
    Write-Host ""

    $index = 1
    $menuMap = @{}

    foreach ($cat in $Config.categories) {
        Write-Host ("[{0}]" -f $cat) -ForegroundColor Green

        $apps = $Config.applications | Where-Object { $_.category -eq $cat }
        foreach ($app in $apps) {
            $key = "{0:00}" -f $index
            Write-Host (" {0}. {1}" -f $key, $app.name)
            $menuMap[$key] = $app
            $index++
        }

        Write-Host ""
    }

    Write-Host "[00] Back"
    Write-Host ""

    return $menuMap
}

# ------------------------------------------------------------
function InstallApps-Menu {
    $config = Load-ApplicationConfig
    if (-not $config) { return }

    while ($true) {
        $menuMap = Show-ApplicationsByCategory -Config $config
        $choice = Read-Host "Select app number"

        if ($choice -eq "00") {
            return
        }

        if ($menuMap.ContainsKey($choice)) {
            Install-Application -App $menuMap[$choice]
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
        else {
            Write-Host "Invalid selection!" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}

# ------------------------------------------------------------
Export-ModuleMember -Function InstallApps-Menu
