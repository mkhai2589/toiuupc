# functions/tweaks.ps1

function Invoke-SystemTweaks {
    param(
        [string]$ConfigPath,
        [string]$BackupPath
    )

    $tweaks = Get-Content $ConfigPath | ConvertFrom-Json

    foreach ($t in $tweaks) {
        try {
            New-Item -Path $t.path -Force | Out-Null
            Set-ItemProperty `
                -Path $t.path `
                -Name $t.name `
                -Value $t.value `
                -Type $t.type
        }
        catch {
            Write-Host "Fail: $($t.name)" -ForegroundColor Red
        }
    }

    Write-Host "Tweaks applied"
}
