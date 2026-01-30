# ==================================================
# install-apps.ps1 – INSTALL APPS (FINAL)
# ==================================================

. "$PSScriptRoot\utils.ps1"

function Run-InstallApps {

    Assert-Admin

    $apps = @(
        "Google.Chrome",
        "7zip.7zip",
        "VideoLAN.VLC"
    )

    $step = 1
    foreach ($app in $apps) {
        Write-Step $step "Installing $app"
        winget install --id $app -e --silent
        Write-OK "$app installed"
        $step++
    }

    Pause-Tool
}
