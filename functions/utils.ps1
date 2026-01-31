# =====================================================
# utils.ps1 - CORE UI ENGINE & UTILITIES (FINAL VERSION)
# =====================================================
# Author: Minh Khai
# Version: 2.0.0
# Description: Core utilities for PMK Toolbox
# =====================================================

# =====================================================
# COLOR SCHEME - PROFESSIONAL & CONSISTENT
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
    Label       = 'Gray'
    Value       = 'White'
    Highlight   = 'Magenta'
    Dim         = 'DarkGray'
}

# =====================================================
# UI CONSTANTS
# =====================================================
$global:UI_Width = 55

# =====================================================
# ADMIN CHECK FUNCTION
# =====================================================
function Test-IsAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Host "[ERROR] Vui long chay voi quyen Administrator!" -ForegroundColor Red
        Write-Host "Chuong trinh se dong trong 3 giay..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        exit 1
    }
}

# =====================================================
# STATUS MESSAGES (FIXED)
# =====================================================
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

# =====================================================
# SYSTEM INFORMATION (FIXED REALTIME)
# =====================================================
function Get-FormattedSystemInfo {
    $info = @{}
    
    # User va Computer Name
    $info.User = $env:USERNAME
    $info.Computer = $env:COMPUTERNAME
    
    # OS Version
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $info.OS = $os.Caption.Trim() -replace "Microsoft ", ""
            $info.Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
            $info.Build = $os.BuildNumber
        } else {
            $info.OS = "Windows"
            $info.Arch = "N/A"
            $info.Build = "N/A"
        }
    } catch {
        $info.OS = "Windows"
        $info.Arch = "N/A"
        $info.Build = "N/A"
    }
    
    # Network Status
    try {
        $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
        if ($adapters) {
            $info.Network = "Connected"
        } else {
            $info.Network = "No Internet"
        }
    } catch {
        $info.Network = "Unknown"
    }
    
    # Admin Status
    $info.IsAdmin = if (Test-IsAdmin) { "YES" } else { "NO" }
    
    # Time Zone - FIXED: Hiển thị múi giờ và vị trí
    try {
        $tz = Get-TimeZone -ErrorAction SilentlyContinue
        $info.TimeZone = "Hanoi UTC+7"
    } catch {
        $info.TimeZone = "Hanoi UTC+7"
    }
    
    $info.LocalTime = Get-Date -Format "HH:mm:ss"
    $info.FullTime = "$($info.LocalTime) $($info.TimeZone)"
    
    # CPU Usage real-time
    try {
        $cpu = Get-WmiObject Win32_Processor -ErrorAction SilentlyContinue | Measure-Object LoadPercentage -Average
        if ($cpu -and $cpu.Average -ge 0) {
            $info.CPU = "$([math]::Round($cpu.Average))%"
        } else {
            $info.CPU = "0%"
        }
    } catch {
        $info.CPU = "0%"
    }
    
    # RAM Usage real-time
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os -and $os.TotalVisibleMemorySize -gt 0) {
            $ramUsed = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
            $ramPercent = [math]::Round(($ramUsed / $os.TotalVisibleMemorySize) * 100)
            $info.RAM = "$ramPercent%"
        } else {
            $info.RAM = "0%"
        }
    } catch {
        $info.RAM = "0%"
    }
    
    # Disk Information - HIEN THI RO HON
    try {
        $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | 
                  Where-Object { $_.Used -and $_.Free -and $_.Name -match '^[A-Z]$' }
        $diskInfo = @()
        foreach ($drive in $drives | Select-Object -First 3) {
            $freeGB = [math]::Round($drive.Free / 1GB, 1)
            $usedGB = [math]::Round($drive.Used / 1GB, 1)
            $totalGB = $freeGB + $usedGB
            if ($totalGB -gt 0) {
                $percent = [math]::Round(($usedGB / $totalGB) * 100)
                $diskInfo += "$($drive.Name): $usedGB/$totalGB GB ($percent%)"
            }
        }
        $info.Disks = if ($diskInfo.Count -gt 0) { $diskInfo -join ' | ' } else { "No disk info" }
    } catch {
        $info.Disks = "Disk info error"
    }
    
    # GPU Information - KHONG CAT CHU
    try {
        $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gpu -and $gpu.Name) {
            $gpuName = ($gpu.Name -split '\(R\)' | Select-Object -First 1).Trim()
            $info.GPU = $gpuName
        } else {
            $info.GPU = "Integrated Graphics"
        }
    } catch {
        $info.GPU = "Unknown"
    }
    
    return $info
}

# =====================================================
# HEADER RENDERING (FIXED)
# =====================================================
function Show-Header {
    param([string]$Title = "TOI UU PC - PMK TOOLBOX")
    
    Clear-Host
    
    # Fixed header - Không có *50
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "           PMK TOOLBOX v2.0                      " -ForegroundColor Cyan
    Write-Host "      Toi Uu He Thong Windows                    " -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "Tac gia: Minh Khai - 0333090930" -ForegroundColor DarkGray
    Write-Host ""
    
    $info = Get-FormattedSystemInfo
    
    # System info in simple format - FIXED: Computer Name thay vì PC
    Write-Host "SYSTEM STATUS:" -ForegroundColor White
    Write-Host "  User: $($info.User) | Computer Name: $($info.Computer) | Admin: $($info.IsAdmin)" -ForegroundColor Gray
    Write-Host "  OS: $($info.OS) $($info.Arch) | Build: $($info.Build)" -ForegroundColor Gray
    Write-Host "  CPU: $($info.CPU) | RAM: $($info.RAM) | GPU: $($info.GPU)" -ForegroundColor Gray
    Write-Host "  Disk: $($info.Disks)" -ForegroundColor Gray
    Write-Host "  Network: $($info.Network) | Time: $($info.FullTime)" -ForegroundColor Gray
    Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

# =====================================================
# MENU RENDERING (FIXED - 1 CỘT ĐƠN GIẢN)
# =====================================================
function Show-Menu {
    param(
        [Parameter(Mandatory)]
        [array]$MenuItems,
        [string]$Title = "MENU",
        [string]$Prompt = "Nhap lua chon:"
    )
    
    Clear-Host
    Show-Header -Title $Title
    
    Write-Host $Title.ToUpper() -ForegroundColor White
    Write-Host ("-" * [Math]::Min($Title.Length, $global:UI_Width - 10)) -ForegroundColor DarkGray
    Write-Host ""
    
    # Hiển thị menu 1 cột với khoảng cách dòng
    foreach ($item in $MenuItems) {
        Write-Host ""  # Thêm dòng trống giữa các mục
        Write-Host "  [$($item.Key)] $($item.Text)" -ForegroundColor $global:UI_Colors.Menu
    }
    
    Write-Host ""
    Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host $Prompt -ForegroundColor Green -NoNewline
}

# =====================================================
# UTILITY FUNCTIONS
# =====================================================
function Pause {
    Write-Host ""
    Write-Host "Nhan Enter de tiep tuc..." -ForegroundColor Yellow -NoNewline
    $null = Read-Host
}

function Load-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Status "Khong tim thay file: $Path" -Type 'ERROR'
        return $null
    }
    
    try {
        $content = Get-Content $Path -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    } catch {
        Write-Status "Dinh dang JSON khong hop le: $Path" -Type 'ERROR'
        return $null
    }
}

# =====================================================
# INITIALIZATION
# =====================================================
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
} catch {
    # Ignore encoding errors
}
