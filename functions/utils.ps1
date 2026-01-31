# =====================================================
# utils.ps1 - CORE UI ENGINE & UTILITIES (FIXED FINAL)
# =====================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

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
}

# =====================================================
# UI CONSTANTS
# =====================================================
$global:UI_Width = 85
$global:UI_ColumnWidth = 40
$global:UI_MaxItemLength = 35

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
        Write-Status "Vui long chay voi quyen Administrator!" -Type 'ERROR'
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
# SYSTEM INFORMATION (FIXED REALTIME - NO ERRORS)
# =====================================================
function Get-FormattedSystemInfo {
    $info = @{}
    
    # User và Computer Name
    $info.User = $env:USERNAME
    $info.Computer = $env:COMPUTERNAME
    
    # OS Version (detailed) - FIXED ERROR
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $info.OS = $os.Caption.Trim() -replace "Microsoft ", ""
            $info.Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
            $info.Build = $os.BuildNumber
            $info.Version = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion
            if (-not $info.Version) { $info.Version = "N/A" }
        } else {
            $info.OS = "Windows"
            $info.Arch = "N/A"
            $info.Build = "N/A"
            $info.Version = "N/A"
        }
    } catch {
        $info.OS = "Windows"
        $info.Arch = "N/A"
        $info.Build = "N/A"
        $info.Version = "N/A"
    }
    
    # Network Status - FIXED ERROR
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
    
    # Time Zone - FIXED ERROR
    try {
        $tz = Get-TimeZone -ErrorAction SilentlyContinue
        $city = if ($tz) { 
            switch ($tz.Id) {
                "SE Asia Standard Time" { "Hanoi" }
                default { $tz.Id }
            }
        } else { "Hanoi" }
        $offset = [System.TimeZoneInfo]::Local.BaseUtcOffset
        $offsetStr = if ($offset.Hours -ge 0) { "+$($offset.Hours)" } else { "$($offset.Hours)" }
        $info.TimeZone = "$city UTC$offsetStr"
    } catch {
        $info.TimeZone = "Hanoi UTC+7"
    }
    
    $info.LocalTime = Get-Date -Format "HH:mm:ss"
    
    # CPU Usage real-time - FIXED ERROR
    try {
        $cpu = Get-WmiObject Win32_Processor -ErrorAction SilentlyContinue | Measure-Object LoadPercentage -Average
        if ($cpu -and $cpu.Average -ge 0) {
            $info.CPU = "$([math]::Round($cpu.Average))%"
        } else {
            $info.CPU = "N/A"
        }
    } catch {
        $info.CPU = "N/A"
    }
    
    # RAM Usage real-time - FIXED ERROR
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os -and $os.TotalVisibleMemorySize -gt 0) {
            $ramUsed = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
            $ramPercent = [math]::Round(($ramUsed / $os.TotalVisibleMemorySize) * 100)
            $info.RAM = "$ramPercent%"
        } else {
            $info.RAM = "N/A"
        }
    } catch {
        $info.RAM = "N/A"
    }
    
    # Disk Information - FIXED ERROR
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
                $diskInfo += "$($drive.Name): ${percent}%"
            }
        }
        $info.Disks = if ($diskInfo.Count -gt 0) { $diskInfo -join ' ' } else { "N/A" }
    } catch {
        $info.Disks = "N/A"
    }
    
    # GPU Information - FIXED ERROR
    try {
        $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gpu -and $gpu.Name) {
            $gpuName = ($gpu.Name -split '\(R\)' | Select-Object -First 1).Trim()
            # Giới hạn độ dài GPU name
            if ($gpuName.Length -gt 25) {
                $gpuName = $gpuName.Substring(0, 22) + "..."
            }
            $info.GPU = $gpuName
        } else {
            $info.GPU = "N/A"
        }
    } catch {
        $info.GPU = "N/A"
    }
    
    return $info
}

# =====================================================
# HEADER RENDERING (FIXED)
# =====================================================
function Show-Header {
    param([string]$Title = "TOI UU PC - PMK TOOLBOX")
    
    Clear-Host
    
    # Simple header
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "           PMK TOOLBOX v1.0                      " -ForegroundColor Cyan
    Write-Host "      Toi Uu He Thong Windows                    " -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "Tac gia: Minh Khai - 0333090930" -ForegroundColor DarkGray
    Write-Host ""
    
    $info = Get-FormattedSystemInfo
    
    # System info in simple format
    Write-Host "SYSTEM STATUS:" -ForegroundColor White
    Write-Host "  User: $($info.User) | PC: $($info.Computer) | Admin: $($info.IsAdmin)" -ForegroundColor Gray
    Write-Host "  OS: $($info.OS) $($info.Arch) | Build: $($info.Build)" -ForegroundColor Gray
    Write-Host "  CPU: $($info.CPU) | RAM: $($info.RAM) | GPU: $($info.GPU)" -ForegroundColor Gray
    Write-Host "  Disk: $($info.Disks)" -ForegroundColor Gray
    Write-Host "  Network: $($info.Network) | Time: $($info.LocalTime) $($info.TimeZone)" -ForegroundColor Gray
    Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

# =====================================================
# MENU RENDERING (FIXED - TWO COLUMN PROPER SPACING)
# =====================================================
function Show-Menu {
    param(
        [Parameter(Mandatory)]
        [array]$MenuItems,
        [string]$Title = "MENU",
        [switch]$TwoColumn = $false,
        [string]$Prompt = "Nhap lua chon:"
    )
    
    Show-Header -Title $Title
    
    Write-Host $Title.ToUpper() -ForegroundColor White
    Write-Host ("-" * [Math]::Min($Title.Length, $global:UI_Width - 10)) -ForegroundColor DarkGray
    Write-Host ""
    
    if ($TwoColumn) {
        $mid = [Math]::Ceiling($MenuItems.Count / 2)
        
        for ($i = 0; $i -lt $mid; $i++) {
            $left = $MenuItems[$i]
            $right = if (($i + $mid) -lt $MenuItems.Count) { $MenuItems[$i + $mid] } else { $null }
            
            # Format left item
            $leftText = $left.Text
            if ($leftText.Length -gt $global:UI_MaxItemLength) {
                $leftText = $leftText.Substring(0, $global:UI_MaxItemLength - 3) + "..."
            }
            
            # Format right item
            $rightText = ""
            if ($right) {
                $rightText = $right.Text
                if ($rightText.Length -gt $global:UI_MaxItemLength) {
                    $rightText = $rightText.Substring(0, $global:UI_MaxItemLength - 3) + "..."
                }
            }
            
            # Display with proper spacing
            $leftDisplay = "  [$($left.Key)] $leftText"
            Write-Host $leftDisplay.PadRight($global:UI_ColumnWidth) -NoNewline -ForegroundColor Gray
            
            if ($right) {
                Write-Host "[$($right.Key)] $rightText" -ForegroundColor Gray
            } else {
                Write-Host ""
            }
        }
    } else {
        foreach ($item in $MenuItems) {
            Write-Host "  [$($item.Key)] $($item.Text)" -ForegroundColor Gray
        }
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
    Read-Host | Out-Null
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
