function Test-Winget {
    try {
        winget --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Set-RegistryTweak {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord",
        [switch]$CreatePath
    )
    try {
        if ($CreatePath -and !(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Warning "Registry error: $_"
        return $false
    }
}

function Remove-WindowsApp {
    param([string]$Pattern)
    $removed = 0
    Get-AppxPackage -AllUsers | Where-Object {$_.Name -like $Pattern} | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; $removed++
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like $Pattern} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; $removed++
    return $removed
}

function Get-SystemInfoText {
    try {
        $os = Get-WmiObject Win32_OperatingSystem
        $cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
        $cs = Get-WmiObject Win32_ComputerSystem
        $gpu = Get-WmiObject Win32_VideoController | Select-Object -First 1
        $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"

        $osName = $os.Caption
        $osBuild = $os.BuildNumber

        $cpuName = $cpu.Name.Trim()
        $cpuCores = $cpu.NumberOfCores
        $cpuSpeed = [math]::Round($cpu.MaxClockSpeed / 1000, 2)

        $totalRAM = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)

        $gpuName = $gpu.Name
        $gpuRAM = [math]::Round($gpu.AdapterRAM / 1GB, 2)

        $diskInfo = ""
        foreach ($disk in $disks) {
            $drive = $disk.DeviceID
            $size = [math]::Round($disk.Size / 1GB, 2)
            $free = [math]::Round($disk.FreeSpace / 1GB, 2)
            $used = $size - $free
            $diskInfo += " • $drive Tổng: $size GB | Đã dùng: $used GB | Trống: $free GB`n"
        }

        return @"
══════════════════════════════════════════════════════════════════════
                  THÔNG TIN HỆ THỐNG
📊 Hệ điều hành:
   • Tên: $osName
   • Build: $osBuild
⚡ CPU:
   • Model: $cpuName
   • Số nhân: $cpuCores
   • Tốc độ: $cpuSpeed GHz
💾 RAM:
   • Tổng: $totalRAM GB
🎮 GPU:
   • Card màn hình: $gpuName
   • Bộ nhớ: $gpuRAM GB
💿 Ổ đĩa:
$diskInfo
══════════════════════════════════════════════════════════════════════
"@
    } catch {
        return "Lỗi lấy info: $_"
    }
}

function Create-RestorePoint {
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "PMK Toolbox - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
        return "✅ Đã tạo điểm khôi phục"
    } catch {
        return "⚠️ Không thể tạo điểm khôi phục: $_"
    }
}

function Is-Windows11 {
    [System.Environment]::OSVersion.Version.Build -ge 22000
}
