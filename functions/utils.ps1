# =====================================================
# utils.ps1 - CORE UI ENGINE & UTILITIES (FINAL)
# =====================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# =====================================================
# COLOR SCHEME - PROFESSIONAL & CONSISTENT
# =====================================================
$global:UI_Colors = @{
    # Core UI
    Border      = 'DarkGray'
    Header      = 'Cyan'
    Title       = 'White'
    Menu        = 'Gray'
    Active      = 'Green'
    
    # Status
    Success     = 'Green'
    Warning     = 'Yellow'
    Error       = 'Red'
    Info        = 'DarkCyan'
    
    # Data
    Label       = 'Gray'
    Value       = 'White'
    Highlight   = 'Magenta'
}

# =====================================================
# UI CONSTANTS
# =====================================================
$global:UI_Width = 70
$global:UI_ColumnWidth = 35

# =====================================================
# SYSTEM INFORMATION (ADVANCED)
# =====================================================
function Get-FormattedSystemInfo {
    $info = @{}
    
    # User
    $info.User = $env:USERNAME
    
    # OS Version (detailed)
    $os = Get-CimInstance Win32_OperatingSystem
    $info.OS = $os.Caption.Trim() -replace "Microsoft ", ""
    $info.Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    $info.Build = $os.BuildNumber
    $info.Version = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
    
    # Network Status with bandwidth check
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        if ($adapters) {
            $mainAdapter = $adapters | Select-Object -First 1
            $speed = if ($mainAdapter.LinkSpeed) { "$($mainAdapter.LinkSpeed)" } else { "Connected" }
            $info.Network = "OK ($speed)"
        } else {
            $info.Network = "No Internet"
        }
    } catch {
        $info.Network = "Unknown"
    }
    
    # Admin Status
    $info.IsAdmin = if (Test-IsAdmin) { "YES" } else { "NO" }
    
    # Time Zone with city
    try {
        $tz = Get-TimeZone
        $tzName = $tz.Id
        $city = switch ($tzName) {
            "SE Asia Standard Time" { "Hanoi/Bangkok" }
            "Tokyo Standard Time" { "Tokyo" }
            "Central European Time" { "Berlin/Paris" }
            "Eastern Standard Time" { "New York" }
            "Pacific Standard Time" { "Los Angeles" }
            default { $tzName }
        }
        $info.TimeZone = "UTC$($tz.BaseUtcOffset.Hours.ToString('+0;-0')) ($city)"
    } catch {
        $info.TimeZone = "UTC+7 (Hanoi)"
    }
    
    $info.LocalTime = Get-Date -Format "HH:mm:ss"
    
    # System resources
    $cpu = Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average
    $info.CPU = if ($cpu.Average) { "$([math]::Round($cpu.Average))%" } else { "N/A" }
    
    $os = Get-CimInstance Win32_OperatingSystem
    $ramUsed = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
    $ramPercent = [math]::Round(($ramUsed / $os.TotalVisibleMemorySize) * 100)
    $info.RAM = "$ramPercent%"
    
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

function Test-NetworkConnection {
    try {
        $test = Test-NetConnection -ComputerName "8.8.8.8" -InformationLevel Quiet -ErrorAction Stop
        return $test
    } catch {
        return $false
    }
}

# =====================================================
# HEADER RENDERING (ADVANCED DASHBOARD)
# =====================================================
function Show-Header {
    param(
        [string]$Title = "TOI UU PC - PMK TOOLBOX",
        [switch]$ShowLogo = $false
    )
    
    Clear-Host
    
    # Show logo if requested
    if ($ShowLogo) {
        Show-PMKLogo
    }
    
    # Get system info
    $info = Get-FormattedSystemInfo
    
    # Build status lines with proper formatting
    $line1Parts = @(
        "USER: $($info.User)",
        "OS: $($info.OS) $($info.Arch)",
        "NET: $($info.Network)"
    )
    
    $line2Parts = @(
        "ADMIN: $($info.IsAdmin)",
        "TIME: $($info.LocalTime)",
        "ZONE: $($info.TimeZone)"
    )
    
    # Calculate padding for centered display
    $line1 = $line1Parts -join " | "
    $line2 = $line2Parts -join " | "
    
    $border = "+" + ("=" * ($global:UI_Width - 2)) + "+"
    
    # Draw border
    Write-Host $border -ForegroundColor $global:UI_Colors.Border
    
    # Line 1
    Write-Host "|" -NoNewline -ForegroundColor $global:UI_Colors.Border
    Write-Host (" " + $line1.PadRight($global:UI_Width - 3)) -NoNewline -ForegroundColor $global:UI_Colors.Header
    Write-Host "|" -ForegroundColor $global:UI_Colors.Border
    
    # Line 2
    Write-Host "|" -NoNewline -ForegroundColor $global:UI_Colors.Border
    Write-Host (" " + $line2.PadRight($global:UI_Width - 3)) -NoNewline -ForegroundColor $global:UI_Colors.Header
    Write-Host "|" -ForegroundColor $global:UI_Colors.Border
    
    # Border bottom
    Write-Host $border -ForegroundColor $global:UI_Colors.Border
    Write-Host ""
}

# =====================================================
# MENU RENDERING (SIMPLE NUMBER INPUT)
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
    
    # Title
    Write-Host $Title.ToUpper() -ForegroundColor $global:UI_Colors.Title
    Write-Host ("-" * $Title.Length) -ForegroundColor $global:UI_Colors.Border
    Write-Host ""
    
    if ($TwoColumn) {
        # Two-column layout
        $mid = [Math]::Ceiling($MenuItems.Count / 2)
        
        for ($i = 0; $i -lt $mid; $i++) {
            $left = $MenuItems[$i]
            $right = if (($i + $mid) -lt $MenuItems.Count) { $MenuItems[$i + $mid] } else { $null }
            
            $leftText = "  [$($left.Key)] $($left.Text)".PadRight($global:UI_ColumnWidth)
            Write-Host $leftText -NoNewline -ForegroundColor $global:UI_Colors.Menu
            
            if ($right) {
                $rightText = "[$($right.Key)] $($right.Text)"
                Write-Host $rightText -ForegroundColor $global:UI_Colors.Menu
            } else {
                Write-Host ""
            }
        }
    } else {
        # Single column
        foreach ($item in $MenuItems) {
            Write-Host "  [$($item.Key)] $($item.Text)" -ForegroundColor $global:UI_Colors.Menu
        }
    }
    
    Write-Host ""
    Write-Host $Prompt -ForegroundColor $global:UI_Colors.Label -NoNewline
}

# =====================================================
# STATUS MESSAGES
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
        'SUCCESS' { '[✓]' }
        'WARNING' { '[!]' }
        'ERROR'   { '[✗]' }
        default   { '[i]' }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

# =====================================================
# UTILITY FUNCTIONS
# =====================================================
function Pause {
    Write-Host ""
    Read-Host "Nhan Enter de tiep tuc"
}

function Load-JsonFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
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
