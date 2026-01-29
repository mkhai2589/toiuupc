function Invoke-AppInstaller {
    param([string]$ConfigPath)

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Khong tim thay file ung dung"
        return
    }

    $apps = Get-Content $ConfigPath | ConvertFrom-Json

    foreach ($a in $apps) {
        Write-Host "Dang cai $($a.id)"
        winget install --id $a.id -e --silent
    }

    Write-Host "Cai dat hoan tat"
}
