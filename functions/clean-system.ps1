# ==================================================
# clean-system.ps1 – CLEAN (FINAL)
# ==================================================

. "$PSScriptRoot\utils.ps1"

function Run-CleanSystem {

    Assert-Admin

    Write-Step 1 "Cleaning TEMP"
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-OK "Temp cleaned"

    Write-Step 2 "Cleaning Windows Update cache"
    Stop-Service wuauserv -Force
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force
    Start-Service wuauserv
    Write-OK "Update cache cleaned"

    Pause-Tool
}
