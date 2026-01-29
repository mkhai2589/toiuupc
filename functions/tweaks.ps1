# tweaks.ps1
# Windows optimization engine

Set-StrictMode -Off

function Apply-RegistryTweak {
    param($Item)

    try {
        if (-not (Test-Path $Item.Path)) {
            New-Item -Path $Item.Path -Force | Out-Null
        }

        Set-ItemProperty `
            -Path $Item.Path `
            -Name $Item.Name `
            -Value $Item.Value `
            -Type $Item.Type `
            -Force

        Write-Log "tweaks" "Applied $($Item.Path)\$($Item.Name)"
    }
    catch {
        Write-Log "tweaks" "Failed $($Item.Path)\$($Item.Name)"
    }
}

function Apply-ServiceTweak {
    param($Item)

    try {
        Set-Service `
            -Name $Item.Name `
            -StartupType $Item.Startup `
            -ErrorAction SilentlyContinue

        if ($Item.State -eq "Stopped") {
            Stop-Service $Item.Name -Force -ErrorAction SilentlyContinue
        }

        Write-Log "tweaks" "Service $($Item.Name)"
    }
    catch {
        Write-Log "tweaks" "Service failed $($Item.Name)"
    }
}

function Invoke-SystemTweaks {
    param([string]$ConfigPath)

    Require-Admin
    Write-Host "Dang ap dung tweaks..."

    $cfg = Read-JsonFile $ConfigPath

    foreach ($r in $cfg.registry) {
        Apply-RegistryTweak $r
    }

    foreach ($s in $cfg.services) {
        Apply-ServiceTweak $s
    }

    Write-Host "Toi uu Windows hoan tat"
}
