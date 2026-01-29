# ==========================================================
# dashboard-engine.ps1
# PMK Toolbox - Performance Dashboard Engine (FIXED)
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ==========================================================
# LOAD WPF
# ==========================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ==========================================================
# LOAD DASHBOARD XAML
# ==========================================================
$XamlPath = Join-Path $PSScriptRoot "..\ui\Dashboard.xaml"

if (-not (Test-Path $XamlPath)) {
    Write-Host "Dashboard.xaml not found" -ForegroundColor Red
    return
}

try {
    [xml]$xaml = Get-Content $XamlPath -Raw
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $Window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Host "Failed to load Dashboard.xaml" -ForegroundColor Red
    return
}

# ==========================================================
# SAFE UI HELPERS
# ==========================================================
function Set-TextSafe {
    param($Ctrl, [string]$Text)
    if ($Ctrl -and $Ctrl.PSObject.Properties["Text"]) {
        $Ctrl.Dispatcher.Invoke([action]{ $Ctrl.Text = $Text })
    }
}

function Set-ValueSafe {
    param($Ctrl, [int]$Value)
    if ($Ctrl -and $Ctrl.PSObject.Properties["Value"]) {
        $Ctrl.Dispatcher.Invoke([action]{ $Ctrl.Value = $Value })
    }
}

function Set-ForegroundSafe {
    param($Ctrl, [string]$Color)
    if ($Ctrl -and $Ctrl.PSObject.Properties["Foreground"]) {
        $Ctrl.Dispatcher.Invoke([action]{ $Ctrl.Foreground = $Color })
    }
}

function Set-VisibilitySafe {
    param($Ctrl, [string]$State)
    if ($Ctrl -and $Ctrl.PSObject.Properties["Visibility"]) {
        $Ctrl.Dispatcher.Invoke([action]{ $Ctrl.Visibility = $State })
    }
}

# ==========================================================
# BIND CONTROLS
# ==========================================================
$CpuRing   = $Window.FindName("CpuRing")
$CpuText   = $Window.FindName("CpuText")
$CpuBar    = $Window.FindName("CpuBar")

$RamBar    = $Window.FindName("RamBar")
$RamText   = $Window.FindName("RamText")

$DiskBar   = $Window.FindName("DiskBar")
$DiskText  = $Window.FindName("DiskText")
$DiskWarn  = $Window.FindName("DiskWarn")

$CleanText = $Window.FindName("CleanText")
$CleanBar  = $Window.FindName("CleanBar")

# ==========================================================
# PERFORMANCE COUNTERS
# ==========================================================
$cpuCounter = New-Object Diagnostics.PerformanceCounter(
    "Processor",
    "% Processor Time",
    "_Total"
)
$null = $cpuCounter.NextValue()

# ==========================================================
# COLOR HELPER
# ==========================================================
function Set-BarColorSafe {
    param($Bar, [int]$Percent)

    if (-not $Bar) { return }

    if ($Percent -ge 80) {
        Set-ForegroundSafe $Bar "Red"
    } elseif ($Percent -ge 60) {
        Set-ForegroundSafe $Bar "Gold"
    } else {
        Set-ForegroundSafe $Bar "LimeGreen"
    }
}

# ==========================================================
# CPU RING DRAW
# ==========================================================
function Draw-CpuRingSafe {
    param([int]$Percent)

    if (-not $CpuRing) { return }

    $radius = 55
    $center = 65

    $angle  = ($Percent / 100) * 360
    $radian = ($angle - 90) * [Math]::PI / 180

    $x = $center + $radius * [Math]::Cos($radian)
    $y = $center + $radius * [Math]::Sin($radian)

    $largeArc = if ($angle -gt 180) { 1 } else { 0 }

    $geo = "M $center,10 A $radius,$radius 0 $largeArc 1 $x,$y"

    $CpuRing.Dispatcher.Invoke([action]{
        $CpuRing.Data = [Windows.Media.Geometry]::Parse($geo)
    })
}

# ==========================================================
# SYSTEM INFO
# ==========================================================
function Get-RamPercent {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $used = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
        return [Math]::Round(($used / $os.TotalVisibleMemorySize) * 100)
    } catch { return 0 }
}

function Get-DiskPercent {
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        return [Math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100)
    } catch { return 0 }
}

# ==========================================================
# DASHBOARD TIMER
# ==========================================================
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)

$timer.Add_Tick({

    # CPU
    $cpu = [Math]::Round($cpuCounter.NextValue())
    Set-TextSafe  $CpuText "$cpu%"
    Set-ValueSafe $CpuBar  $cpu
    Set-BarColorSafe $CpuBar $cpu
    Draw-CpuRingSafe $cpu

    # RAM
    $ram = Get-RamPercent
    Set-TextSafe  $RamText "$ram%"
    Set-ValueSafe $RamBar  $ram
    Set-BarColorSafe $RamBar $ram

    # DISK
    $disk = Get-DiskPercent
    Set-TextSafe  $DiskText "$disk% used"
    Set-ValueSafe $DiskBar  $disk
    Set-BarColorSafe $DiskBar $disk

    if ($disk -ge 85) {
        Set-VisibilitySafe $DiskWarn "Visible"
    } else {
        Set-VisibilitySafe $DiskWarn "Collapsed"
    }

    # CLEAN STATE
    if ($Global:CleanState) {
        if ($Global:CleanState.Running) {
            Set-TextSafe  $CleanText "Cleaning: $($Global:CleanState.Step)"
            Set-ValueSafe $CleanBar  $Global:CleanState.Percent
        } else {
            if ($Global:CleanState.FreedMB -gt 0) {
                Set-TextSafe  $CleanText "Freed: $($Global:CleanState.FreedMB) MB"
                Set-ValueSafe $CleanBar  100
            } else {
                Set-TextSafe  $CleanText "Idle"
                Set-ValueSafe $CleanBar  0
            }
        }
    } else {
        Set-TextSafe  $CleanText "Idle"
        Set-ValueSafe $CleanBar  0
    }
})

# ==========================================================
# SHOW WINDOW
# ==========================================================
$Window.Add_Closed({
    $timer.Stop()
})

$timer.Start()
$Window.ShowDialog() | Out-Null
