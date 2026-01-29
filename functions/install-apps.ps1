# install-apps.ps1
# Application installer (winget)

Set-StrictMode -Off

function Install-App {
    param($App)

    Write-Host "Cai $($App.name)..."
    Write-Log "apps" "Install $($App.id)"

    $args = @(
        "install",
        "--id", $App.id,
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    Start-Process `
        -FilePath "winget" `
        -ArgumentList $args `
        -Wait `
        -NoNewWindow
}

function Invoke-AppInstaller {
    param([string]$ConfigPath)

    Require-Admin

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Winget not found"
        return
    }

    $cfg = Read-JsonFile $ConfigPath

    foreach ($app in $cfg.applications) {
        Install-App $app
    }

    Write-Host "Cai ung dung hoan tat"
}
