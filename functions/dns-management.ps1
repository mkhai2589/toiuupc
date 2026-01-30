# ==========================================================
# dns-management.ps1
# PMK Toolbox - DNS Management Engine
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==========================================================
# LOG
# ==========================================================
$Global:DnsLog = Join-Path $Global:LogDir "dns.log"

function Write-DnsLog {
    param([string]$Message)
    Write-Log -Message "[DNS] $Message"
    "$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) $Message" |
        Out-File -FilePath $Global:DnsLog -Append -Encoding UTF8
}

# ==========================================================
# GET ACTIVE ADAPTER
# ==========================================================
function Get-ActiveNetworkAdapter {
    try {
        return Get-NetAdapter |
            Where-Object {
                $_.Status -eq "Up" -and
                $_.HardwareInterface -eq $true
            } |
            Sort-Object -Property InterfaceMetric |
            Select-Object -First 1
    }
    catch {
        return $null
    }
}

# ==========================================================
# GET CURRENT DNS
# ==========================================================
function Get-CurrentDns {
    param([string]$InterfaceAlias)

    try {
        $dns = Get-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily IPv4 `
            -ErrorAction Stop

        return $dns.ServerAddresses
    }
    catch {
        return @()
    }
}

# ==========================================================
# APPLY DNS
# ==========================================================
function Apply-Dns {
    param(
        [string]$InterfaceAlias,
        [string[]]$Servers
    )

    try {
        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -ServerAddresses $Servers `
            -ErrorAction Stop

        Write-DnsLog "Applied DNS [$($Servers -join ', ')] on $InterfaceAlias"
        return $true
    }
    catch {
        Write-DnsLog "Failed apply DNS on $InterfaceAlias"
        return $false
    }
}

# ==========================================================
# RESTORE DHCP DNS
# ==========================================================
function Restore-DhcpDns {
    param([string]$InterfaceAlias)

    try {
        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -ResetServerAddresses `
            -ErrorAction Stop

        Write-DnsLog "Restored DHCP DNS on $InterfaceAlias"
        return $true
    }
    catch {
        Write-DnsLog "Failed restore DHCP DNS on $InterfaceAlias"
        return $false
    }
}

# ==========================================================
# LOAD CONFIG
# ==========================================================
function Load-DnsConfig {
    $cfgPath = Join-Path $Global:ConfigDir "dns.json"

    if (-not (Test-Path $cfgPath)) {
        Write-Host "dns.json not found" -ForegroundColor Red
        return $null
    }

    try {
        return Get-Content $cfgPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host "Invalid dns.json format" -ForegroundColor Red
        return $null
    }
}

# ==========================================================
# MENU
# ==========================================================
function Invoke-DnsMenu {

    $Config = Load-DnsConfig
    if (-not $Config) { return }

    $Adapter = Get-ActiveNetworkAdapter
    if (-not $Adapter) {
        Write-Host "No active network adapter found" -ForegroundColor Red
        Read-Host "Press Enter"
        return
    }

    $iface = $Adapter.InterfaceAlias

    while ($true) {
        Clear-Screen
        Write-Host "DNS MANAGEMENT" -ForegroundColor Cyan
        Write-Host "Adapter : $iface"
        Write-Host ""

        $current = Get-CurrentDns $iface
        if ($current.Count -eq 0) {
            Write-Host "Current DNS : DHCP" -ForegroundColor Green
        } else {
            Write-Host "Current DNS : $($current -join ', ')" -ForegroundColor Yellow
        }

        Write-Host ""
        $map = @{}
        $i = 1

        foreach ($p in $Config.providers) {
            Write-Host ("[{0}] {1} ({2})" -f $i, $p.name, ($p.servers -join ", "))
            $map[$i] = $p
            $i++
        }

        Write-Host ""
        Write-Host "[90] Restore DHCP"
        Write-Host "[0]  Back"

        $sel = Read-Choice "Select"

        if ($sel -eq "0") { break }

        if ($sel -eq "90") {
            Restore-DhcpDns $iface | Out-Null
            Start-Sleep 1
            continue
        }

        if ($map.ContainsKey([int]$sel)) {
            $item = $map[[int]$sel]
            Apply-Dns -InterfaceAlias $iface -Servers $item.servers | Out-Null
            Start-Sleep 1
        }
    }
}
