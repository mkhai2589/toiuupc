function Start-DnsManager {
    param([string]$ConfigPath)

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Khong tim thay file DNS"
        return
    }

    $dns = Get-Content $ConfigPath | ConvertFrom-Json

    Write-Host ""
    Write-Host "Danh sach DNS"

    for ($i=0; $i -lt $dns.Count; $i++) {
        Write-Host "$($i+1). $($dns[$i].name)"
    }
    Write-Host "0. Thoat"

    $c = Read-Host "Chon DNS"

    if ($c -eq "0") { return }

    if (-not [int]::TryParse($c,[ref]$null)) {
        Write-Host "Lua chon khong hop le"
        return
    }

    $i = [int]$c - 1
    if ($i -lt 0 -or $i -ge $dns.Count) {
        Write-Host "Lua chon ngoai pham vi"
        return
    }

    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        Set-DnsClientServerAddress `
            -InterfaceIndex $_.InterfaceIndex `
            -ServerAddresses $dns[$i].ipv4
    }

    Write-Host "Da ap dung DNS"
}
