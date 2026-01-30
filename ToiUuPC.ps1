# ==================================================
# ToiUuPC.ps1 – MAIN (FINAL)
# ==================================================

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

$base = $PSScriptRoot
. "$base\functions\utils.ps1"
. "$base\functions\Show-PMKLogo.ps1"
. "$base\functions\tweaks.ps1"
. "$base\functions\install-apps.ps1"
. "$base\functions\dns-management.ps1"
. "$base\functions\clean-system.ps1"

Assert-Admin

while ($true) {

    Clear-Host
    Show-PMKLogo

    Write-Host ""
    Write-Host "1. Windows Tweaks"
    Write-Host "2. Install Applications"
    Write-Host "3. DNS Management"
    Write-Host "4. Clean System"
    Write-Host "0. Exit"

    $c = Read-Host "Select"

    switch ($c) {
        "1" { Run-WindowsTweaks }
        "2" { Run-InstallApps }
        "3" { Run-DNSManagement }
        "4" { Run-CleanSystem }
        "0" { exit }
    }
}
