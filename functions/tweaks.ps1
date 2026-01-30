# ==================================================
# tweaks.ps1 – WINDOWS TWEAKS (FINAL)
# ==================================================

. "$PSScriptRoot\utils.ps1"

function Run-WindowsTweaks {

    Assert-Admin
    Write-Step 1 "Disable Telemetry"

    Set-ItemProperty `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Name AllowTelemetry `
        -Type DWord `
        -Value 0 `
        -Force

    Write-OK "Telemetry disabled"

    Write-Step 2 "Disable Cortana"

    Set-ItemProperty `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name AllowCortana `
        -Type DWord `
        -Value 0 `
        -Force

    Write-OK "Cortana disabled"

    Write-Step 3 "Disable Windows Tips"

    Set-ItemProperty `
        -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name SubscribedContent-338389Enabled `
        -Type DWord `
        -Value 0 `
        -Force

    Write-OK "Tips disabled"

    Pause-Tool
}
