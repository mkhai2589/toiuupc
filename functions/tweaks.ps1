function Invoke-SystemTweaks {
    param([string]$ConfigPath)

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Khong tim thay file tweaks"
        return
    }

    $tweaks = Get-Content $ConfigPath | ConvertFrom-Json

    foreach ($t in $tweaks) {
        try {
            New-Item -Path $t.path -Force | Out-Null
            Set-ItemProperty `
                -Path $t.path `
                -Name $t.name `
                -Value $t.value `
                -Type $t.type
        } catch {
            Write-Host "Khong ap dung duoc tweak $($t.name)"
        }
    }

    Write-Host "Da ap dung toi uu"
}
