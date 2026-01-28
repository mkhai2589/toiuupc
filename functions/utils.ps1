function Test-Winget {
    try { winget --version; return $true } catch { return $false }
}

function Set-RegistryTweak {
    param([string]$Path, [string]$Name, [object]$Value, [string]$Type = "DWord", [switch]$CreatePath)
    try {
        if ($CreatePath -and !(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        return $true
    } catch { Write-Warning "Registry error: $_"; return $false }
}

function Remove-WindowsApp {
    param([string]$Pattern)
    $removed = 0
    Get-AppxPackage -AllUsers | Where-Object Name -like $Pattern | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Pattern | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    return $removed
}

function Get-SystemInfoText {
    # Giữ từ code cũ, tối ưu WMI -> CimInstance từ WinUtil
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select -First 1
    $cs = Get-CimInstance Win32_ComputerSystem
    $gpu = Get-CimInstance Win32_VideoController | Select -First 1
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    # ... (giữ logic format text từ code cũ)
}

function Create-RestorePoint {
    try {
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "PMK Toolbox - $(Get-Date)" -RestorePointType MODIFY_SETTINGS
        return "✅ Created restore point"
    } catch { return "⚠️ Restore point failed: $_" }
}

# Thêm Check-OSVersion từ Raphire
function Is-Windows11 {
    [System.Environment]::OSVersion.Version.Build -ge 22000
}
