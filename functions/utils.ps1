# =====================================================
# utils.ps1 - CORE UI ENGINE & UTILITIES (FINAL IMPROVED)
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
$global:UI_ColumnWidth = 42  # Tăng rộng hơn để tránh dính

# =====================================================
# SYSTEM INFORMATION (ADVANCED - REAL-TIME)
# =====================================================
function Get-FormattedSystemInfo {
    $info = @{}
    
    # User và Computer Name
    $info.User = $env:USERNAME
    $info.Computer = $env:COMPUTERNAME
    
    # OS Version (detailed)
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $info.OS = if ($os) { $os.Caption.Trim() -replace "Microsoft ", "" } else { "Windows Unknown" }
        $info.Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        $info.Build = if ($os) { $os.BuildNumber } else { "N/A" }
        $info.Version = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion
    } catch {
        $info.OS = "Windows"
        $info.Arch = "N/A"
        $info.Build = "N/A"
        $info.Version = "N/A"
    }
    
    # Network Status với tốc độ chính xác
    try {
        $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
        if ($adapters) {
            $mainAdapter = $adapters | Sort-Object InterfaceMetric | Select-Object -First 1
            $speed = if ($mainAdapter.LinkSpeed) { 
                $mainAdapter.LinkSpeed -replace 'bps', '' 
            } else { 
                "Connected" 
            }
            $info.Network = "OK ($speed)"
        } else {
            $info.Network = "No Internet"
        }
    } catch {
        $info.Network = "Unknown"
    }
    
    # Admin Status
    $info.IsAdmin = if (Test-IsAdmin) { "YES" } else { "NO" }
    
    # Time Zone
    try {
        $tz = Get-TimeZone -ErrorAction SilentlyContinue
        $city = if ($tz) { 
            switch ($tz.Id) {
                "SE Asia Standard Time" { "Hanoi" }
                "Tokyo Standard Time" { "Tokyo" }
                "Central European Time" { "Berlin" }
                "Eastern Standard Time" { "New York" }
                default { $tz.Id }
            }
        } else { "Hanoi" }
        $info.TimeZone = "$city UTC$([System.TimeZoneInfo]::Local.BaseUtcOffset.Hours)"
    } catch {
        $info.TimeZone = "Hanoi UTC+7"
    }
    
    $info.LocalTime = Get-Date -Format "HH:mm:ss"
    
    # CPU Usage real-time
    try {
        $cpu = Get-WmiObject Win32_Processor -ErrorAction SilentlyContinue | Measure-Object LoadPercentage -Average
        $info.CPU = if ($cpu.Average) { "$([math]::Round($cpu.Average))%" } else { "N/A" }
    } catch {
        $info.CPU = "N/A"
    }
    
    # RAM Usage real-time
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $ramUsed = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
            $ramPercent = [math]::Round(($ramUsed / $os.TotalVisibleMemorySize) * 100)
            $info.RAM = "$ramPercent%"
        } else {
            $info.RAM = "N/A"
        }
    } catch {
        $info.RAM = "N/A"
    }
    
    # Disk Information
    try {
        $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | 
                  Where-Object { $_.Used -and $_.Free -and $_.Name -match '^[A-Z]$' }
        $diskInfo = @()
        foreach ($drive in $drives | Select-Object -First 3) {
            $freeGB = [math]::Round($drive.Free / 1GB, 1)
            $usedGB = [math]::Round($drive.Used / 1GB, 1)
            $totalGB = $freeGB + $usedGB
            $percent = [math]::Round(($usedGB / $totalGB) * 100)
            $diskInfo += "$($drive.Name): ${percent}%"
        }
        $info.Disks = if ($diskInfo.Count -gt 0) { $diskInfo -join ' ' } else { "N/A" }
    } catch {
        $info.Disks = "N/A"
    }
    
    # GPU Information (đơn giản)
    try {
        $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        $info.GPU = if ($gpu -and $gpu.Name) { 
            ($gpu.Name -split '\(R\)' | Select-Object -First 1).Trim() 
        } else { 
            "N/A" 
        }
    } catch {
        $info.GPU = "N/A"
    }
    
    return $info
}

function Test-IsAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

# =====================================================
# HEADER RENDERING (ADVANCED DASHBOARD)
# =====================================================
function Show-Header {
    param([string]$Title = "TOI UU PC - PMK TOOLBOX")
    
    Clear-Host
    Show-PMKLogo
    
    $info = Get-FormattedSystemInfo
    
    # Build status lines
    $line1Parts = @(
        "USER: $($info.User)",
        "PC: $($info.Computer)",
        "OS: $($info.OS) $($info.Arch)",
        "NET: $($info.Network)"
    )
    
    $line2Parts = @(
        "ADMIN: $($info.IsAdmin)",
        "CPU: $($info.CPU)",
        "RAM: $($info.RAM)",
        "GPU: $($info.GPU)"
    )
    
    $line3Parts = @(
        "TIME: $($info.LocalTime)",
        "ZONE: $($info.TimeZone)",
        "DISK: $($info.Disks)",
        "BUILD: $($info.Build)"
    )
    
    $border = "+" + ("=" * ($global:UI_Width - 2)) + "+"
    
    Write-Host $border -ForegroundColor $global:UI_Colors.Border
    
    # Line 1
    Write-Host "|" -NoNewline -ForegroundColor $global:UI_Colors.Border
    $line1 = (" " + ($line1Parts -join " | ")).PadRight($global:UI_Width - 1)
    Write-Host $line1 -NoNewline -ForegroundColor $global:UI_Colors.Header
    Write-Host "|" -ForegroundColor $global:UI_Colors.Border
    
    # Line 2
    Write-Host "|" -NoNewline -ForegroundColor $global:UI_Colors.Border
    $line2 = (" " + ($line2Parts -join " | ")).PadRight($global:UI_Width - 1)
    Write-Host $line2 -NoNewline -ForegroundColor $global:UI_Colors.Header
    Write-Host "|" -ForegroundColor $global:UI_Colors.Border
    
    # Line 3
    Write-Host "|" -NoNewline -ForegroundColor $global:UI_Colors.Border
    $line3 = (" " + ($line3Parts -join " | ")).PadRight($global:UI_Width - 1)
    Write-Host $line3 -NoNewline -ForegroundColor $global:UI_Colors.Header
    Write-Host "|" -ForegroundColor $global:UI_Colors.Border
    
    Write-Host $border -ForegroundColor $global:UI_Colors.Border
    Write-Host ""
}

# =====================================================
# MENU RENDERING (IMPROVED SPACING)
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
    
    # Title với khoảng cách
    Write-Host $Title.ToUpper() -ForegroundColor $global:UI_Colors.Title
    Write-Host ("-" * [Math]::Min($Title.Length, $global:UI_Width - 10)) -ForegroundColor $global:UI_Colors.Border
    Write-Host ""
    
    if ($TwoColumn) {
        # Two-column layout với khoảng cách lớn hơn
        $mid = [Math]::Ceiling($MenuItems.Count / 2)
        
        for ($i = 0; $i -lt $mid; $i++) {
            $left = $MenuItems[$i]
            $right = if (($i + $mid) -lt $MenuItems.Count) { $MenuItems[$i + $mid] } else { $null }
            
            # Left column
            $leftText = "  [$($left.Key)] $($left.Text)".PadRight($global:UI_ColumnWidth)
            Write-Host $leftText -NoNewline -ForegroundColor $global:UI_Colors.Menu
            
            # Right column
            if ($right) {
                $rightText = "[$($right.Key)] $($right.Text)".PadRight($global:UI_ColumnWidth)
                Write-Host $rightText -ForegroundColor $global:UI_Colors.Menu
            } else {
                Write-Host ""
            }
            
            Write-Host ""  # Empty line for spacing
        }
    } else {
        # Single column with better spacing
        foreach ($item in $MenuItems) {
            Write-Host "  [$($item.Key)] $($item.Text)" -ForegroundColor $global:UI_Colors.Menu
            Write-Host ""  # Empty line between items
        }
    }
    
    Write-Host ""
    Write-Host "─" * ($global:UI_Width - 20) -ForegroundColor $global:UI_Colors.Border
    Write-Host ""
    Write-Host $Prompt -ForegroundColor $global:UI_Colors.Active -NoNewline
}

# =====================================================
# STATUS MESSAGES (FIXED EMOJI)
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
# UTILITY FUNCTIONS
# =====================================================
function Pause {
    Write-Host ""
    Write-Host "Nhan Enter de tiep tuc..." -ForegroundColor $global:UI_Colors.Warning -NoNewline
    Read-Host
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

function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Status "Vui long chay voi quyen Administrator!" -Type 'ERROR'
        Write-Host "Chuong trinh se dong trong 3 giay..." -ForegroundColor $global:UI_Colors.Warning
        Start-Sleep -Seconds 3
        exit 1
    }
}

# =====================================================
# INITIALIZATION
# =====================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
