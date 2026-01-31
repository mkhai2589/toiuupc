# =====================================================
# utils.ps1 - CORE UI ENGINE & UTILITIES
# =====================================================

$global:UI_Colors = @{
    Border      = 'DarkGray'
    Header      = 'Cyan'
    Title       = 'White'
    Menu        = 'Gray'
    Active      = 'Green'
    Success     = 'Green'
    Warning     = 'Yellow'
    Error       = 'Red'
    Info        = 'DarkCyan'
    Label       = 'DarkGray'
    Value       = 'White'
    Highlight   = 'Magenta'
    Dim         = 'DarkGray'
}

$global:UI_Width = 80

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Host "[ERROR] Vui long chay voi quyen Administrator!" -ForegroundColor Red
        Write-Host "Chuong trinh se dong trong 3 giay..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        exit 1
    }
}

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
        [string]$Type = 'INFO'
    )
    
    $color = switch ($Type) {
        'SUCCESS' { $global:UI_Colors.Success }
        'WARNING' { $global:UI_Colors.Warning }
        'ERROR'   { $global:UI_Colors.Error }
        default   { $global:UI_Colors.Info }
    }
    
    $prefix = switch ($Type) {
        'SUCCESS' { '[OK]' }
        'WARNING' { '[!]' }
        'ERROR'   { '[X]' }
        default   { '[...]' }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Get-FormattedSystemInfo {
    $info = @{}
    
    $info.User = $env:USERNAME
    $info.Computer = $env:COMPUTERNAME
    $info.IsAdmin = if (Test-IsAdmin) { "YES" } else { "NO" }
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $info.OS = ($os.Caption -replace "Microsoft ", "").Trim()
        $info.Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        $info.Build = $os.BuildNumber
    } catch {
        $info.OS = "Windows"
        $info.Arch = "N/A"
        $info.Build = "N/A"
    }
    
    try {
        $adapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }
        $info.Network = if ($adapters) { "OK" } else { "No Internet" }
    } catch {
        $info.Network = "Unknown"
    }
    
    $info.FullTime = "$(Get-Date -Format 'HH:mm:ss') Hanoi UTC+7"
    
    try {
        $cpu = Get-WmiObject Win32_Processor | Measure-Object LoadPercentage -Average
        $info.CPU = "$([math]::Round($cpu.Average))%"
    } catch {
        $info.CPU = "0%"
    }
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $ramUsed = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
        $ramPercent = [math]::Round(($ramUsed / $os.TotalVisibleMemorySize) * 100)
        $info.RAM = "$ramPercent%"
    } catch {
        $info.RAM = "0%"
    }
    
    try {
        $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
        $info.GPU = if ($gpu.Name) { $gpu.Name } else { "Integrated Graphics" }
    } catch {
        $info.GPU = "Unknown"
    }
    
    try {
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match '^[CDEF]$' }
        $diskInfo = @()
        foreach ($drive in $drives) {
            if ($drive.Used -and $drive.Free) {
                $freeGB = [math]::Round($drive.Free / 1GB, 1)
                $usedGB = [math]::Round($drive.Used / 1GB, 1)
                $totalGB = $freeGB + $usedGB
                if ($totalGB -gt 0) {
                    $percent = [math]::Round(($usedGB / $totalGB) * 100)
                    $diskInfo += "$($drive.Name): $usedGB/$totalGB GB ($percent%)"
                }
            }
        }
        $info.Disks = if ($diskInfo.Count -gt 0) { $diskInfo -join ' | ' } else { "No info" }
    } catch {
        $info.Disks = "Error"
    }
    
    return $info
}

function Show-Header {
    param([string]$Title = "")
    
    Clear-Host
    
    $info = Get-FormattedSystemInfo
    
    # ASCII ART HEADER
    Write-Host ""
    Write-Host "+======================================================================+" -ForegroundColor Cyan
    Write-Host ("| USER: {0} | OS: {1} {2} | NET: {3} | ADMIN: {4} | TIME: {5} |" -f 
        $info.User, $info.OS, $info.Arch, $info.Network, $info.IsAdmin, (Get-Date -Format "HH:mm:ss")) -ForegroundColor Cyan
    Write-Host "+======================================================================+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " PMK TOOLBOX - Toi Uu Windows" -ForegroundColor White
    Write-Host " Author : MINH KHAI - 0333090930" -ForegroundColor DarkGray
    Write-Host ""
    
    if ($Title) {
        Write-Host " $Title" -ForegroundColor White
        Write-Host ("-" * $global:UI_Width) -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Show-MainMenu {
    Show-Header
    
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor DarkGray
    Write-Host "|  SYSTEM TWEAK             |  INSTALLER               |" -ForegroundColor White
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor DarkGray
    Write-Host "| [01] Windows Tweaks       | [51] Install Apps        |" -ForegroundColor Gray
    Write-Host "| [02] DNS Management       | [52] Update Winget       |" -ForegroundColor Gray
    Write-Host "| [03] Clean System         |                          |" -ForegroundColor Gray
    Write-Host "| [04] Restore Point        |                          |" -ForegroundColor Gray
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor DarkGray
    Write-Host "|  OTHER / TOOLS            |  EXIT / INFO              |" -ForegroundColor White
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor DarkGray
    Write-Host "| [21] System Info          | [99] Changelog            |" -ForegroundColor Gray
    Write-Host "| [22] Performance          | [00] Exit                 |" -ForegroundColor Gray
    Write-Host "+---------------------------+---------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " Select option > " -ForegroundColor Green -NoNewline
}

function Pause {
    Write-Host ""
    Write-Host " Nhan Enter de tiep tuc..." -ForegroundColor Yellow -NoNewline
    $null = Read-Host
}

function Load-JsonFile {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Status "Khong tim thay file: $(Split-Path $Path -Leaf)" -Type 'ERROR'
        return $null
    }
    
    try {
        return Get-Content $Path -Raw | ConvertFrom-Json
    } catch {
        Write-Status "JSON loi: $(Split-Path $Path -Leaf)" -Type 'ERROR'
        return $null
    }
}

function Show-SystemInfo {
    Show-Header -Title "THONG TIN HE THONG"
    
    $info = Get-FormattedSystemInfo
    
    Write-Host " THONG TIN CO BAN:" -ForegroundColor White
    Write-Host "   Nguoi dung: $($info.User)" -ForegroundColor Gray
    Write-Host "   May tinh: $($info.Computer)" -ForegroundColor Gray
    Write-Host "   He dieu hanh: $($info.OS) $($info.Arch)" -ForegroundColor Gray
    Write-Host "   Build: $($info.Build)" -ForegroundColor Gray
    Write-Host "   Admin: $($info.IsAdmin)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host " TAI NGUYEN:" -ForegroundColor White
    Write-Host "   CPU: $($info.CPU)" -ForegroundColor Gray
    Write-Host "   RAM: $($info.RAM)" -ForegroundColor Gray
    Write-Host "   GPU: $($info.GPU)" -ForegroundColor Gray
    Write-Host "   Disk: $($info.Disks)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host " MANG:" -ForegroundColor White
    Write-Host "   Trang thai: $($info.Network)" -ForegroundColor Gray
    Write-Host "   Thoi gian: $($info.FullTime)" -ForegroundColor Gray
    Write-Host ""
    
    Pause
}

function Show-Performance {
    Show-Header -Title "KIEM TRA HIEN TRANG"
    
    Write-Host " TAI NGUYEN HE THONG:" -ForegroundColor White
    Write-Host ""
    
    # CPU
    try {
        $cpu = Get-WmiObject Win32_Processor | Measure-Object LoadPercentage -Average
        $cpuPercent = [math]::Round($cpu.Average)
        Write-Host "   CPU: $cpuPercent%" -ForegroundColor Gray
        Write-Host "   [" -NoNewline -ForegroundColor DarkGray
        $bars = [math]::Round($cpuPercent / 5)
        1..20 | ForEach-Object {
            if ($_ -le $bars) {
                Write-Host "█" -NoNewline -ForegroundColor $(if ($cpuPercent -gt 80) { "Red" } elseif ($cpuPercent -gt 50) { "Yellow" } else { "Green" })
            } else {
                Write-Host "░" -NoNewline -ForegroundColor DarkGray
            }
        }
        Write-Host "]" -ForegroundColor DarkGray
    } catch {
        Write-Host "   CPU: Khong kiem tra duoc" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # RAM
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedGB = $totalGB - $freeGB
        $ramPercent = [math]::Round(($usedGB / $totalGB) * 100)
        
        Write-Host "   RAM: $ramPercent% ($usedGB/$totalGB GB)" -ForegroundColor Gray
        Write-Host "   [" -NoNewline -ForegroundColor DarkGray
        $bars = [math]::Round($ramPercent / 5)
        1..20 | ForEach-Object {
            if ($_ -le $bars) {
                Write-Host "█" -NoNewline -ForegroundColor $(if ($ramPercent -gt 90) { "Red" } elseif ($ramPercent -gt 70) { "Yellow" } else { "Green" })
            } else {
                Write-Host "░" -NoNewline -ForegroundColor DarkGray
            }
        }
        Write-Host "]" -ForegroundColor DarkGray
    } catch {
        Write-Host "   RAM: Khong kiem tra duoc" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host " DANH GIA:" -ForegroundColor White
    if ($cpuPercent -gt 80 -or $ramPercent -gt 90) {
        Write-Host "   He thong qua tai - Can toi uu ngay!" -ForegroundColor Red
    } elseif ($cpuPercent -gt 60 -or $ramPercent -gt 70) {
        Write-Host "   He thong hoat dong binh thuong" -ForegroundColor Yellow
    } else {
        Write-Host "   He thong hoat dong tot" -ForegroundColor Green
    }
    
    Write-Host ""
    Pause
}

function Show-Changelog {
    Show-Header -Title "THONG TIN PHIEN BAN"
    
    Write-Host " PMK TOOLBOX v2.0" -ForegroundColor White
    Write-Host " Tac gia: Minh Khai" -ForegroundColor Gray
    Write-Host " SDT: 0333090930" -ForegroundColor Gray
    Write-Host " Ngay phat hanh: 2026-01-31" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host " TINH NANG MOI:" -ForegroundColor White
    Write-Host "   - Giao dien moi voi ASCII art" -ForegroundColor Gray
    Write-Host "   - Toi uu hieu nang he thong" -ForegroundColor Gray
    Write-Host "   - Quan ly DNS nang cao" -ForegroundColor Gray
    Write-Host "   - Cai dat ung dung tu dong" -ForegroundColor Gray
    Write-Host "   - Don dep he thong chuyen sau" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host " CAP NHAT:" -ForegroundColor White
    Write-Host "   - Fix loi DNS khong hien thi IPv4/IPv6" -ForegroundColor Gray
    Write-Host "   - Cai dat winget tu dong" -ForegroundColor Gray
    Write-Host "   - Them nhieu tweaks moi" -ForegroundColor Gray
    Write-Host "   - Toi uu toc do load menu" -ForegroundColor Gray
    Write-Host ""
    
    Pause
}
