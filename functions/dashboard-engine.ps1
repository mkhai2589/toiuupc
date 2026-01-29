# ==========================================================
# dashboard-engine.ps1
# PMK Toolbox - Performance Dashboard Engine
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

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
    Write-Log "Dashboard.xaml not found" "ERROR"
    return
}

[xml]$xaml = Get-Content $XamlPath -Raw
$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

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
$cpuCounter.NextValue() | Out-Null

# ==========================================================
# COLOR HELPER
# ==========================================================
function Set-BarColor {
    param($Bar, [int]$Percent)

    if ($Percent -ge 80) {
        $Bar.Foreground = "Red"
    } elseif ($Percent -ge 60) {
        $Bar.Foreground = "Gold"
    } else {
        $Bar.Foreground = "LimeGreen"
    }
}

# ==========================================================
# CPU RING DRAW (SMOOTH)
# ==========================================================
function Draw-CpuRing {
    param([int]$Percent)

    $radius = 55
    $center = 65

    $angle = ($Percent / 100) * 360
    $radian = ($angle - 90) * [Math]::PI / 180

    $x = $center + $radius * [Math]::Cos($radian)
    $y = $center + $radius * [Math]::Sin($radian)

    $largeArc = if ($angle -gt 180) { 1 } else { 0 }

    $CpuRing.Data = [Windows.Media.Geometry]::Parse(
        "M $center,10 A $radius,$radius 0 $largeArc 1 $x,$y"
    )
}

# ==========================================================
# SYSTEM INFO HELPERS
# ==========================================================
function Get-RamPercent {
    $os = Get-CimInstance Win32_OperatingSystem
    $used = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
    return [Math]::Round(($used / $os.TotalVisibleMemorySize) * 100)
}

function Get-DiskPercent {
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    return [Math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100)
}

# ==========================================================
# DASHBOARD UPDATE LOOP
# ==========================================================
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(1000)

$timer.Add_Tick({

    # =========================
    # CPU
    # =========================
    $cpu = [Math]::Round($cpuCounter.NextValue())
    $CpuText.Text = "$cpu%"
    $CpuBar.Value = $cpu
    Set-BarColor $CpuBar $cpu
    Draw-CpuRing $cpu

    # =========================
    # RAM
    # =========================
    $ram = Get-RamPercent
    $RamText.Text = "$ram%"
    $RamBar.Value = $ram
    Set-BarColor $RamBar $ram

    # =========================
    # DISK
    # =========================
    $disk = Get-DiskPercent
    $DiskText.Text = "$disk% used"
    $DiskBar.Value = $disk
    Set-BarColor $DiskBar $disk

    $DiskWarn.Visibility = if ($disk -ge 85) {
        "Visible"
    } else {
        "Collapsed"
    }

    # =========================
    # CLEAN SYSTEM (BACKGROUND)
    # =========================
    if ($Global:CleanState) {

        if ($Global:CleanState.Running) {
            $CleanText.Text = "Cleaning: $($Global:CleanState.Step)"
            $CleanBar.Value = $Global:CleanState.Percent
        } else {
            if ($Global:CleanState.FreedMB -gt 0) {
                $CleanText.Text = "Freed: $($Global:CleanState.FreedMB) MB"
                $CleanBar.Value = 100
            } else {
                $CleanText.Text = "Idle"
                $CleanBar.Value = 0
            }
        }
    }

})

# ==========================================================
# SHOW DASHBOARD
# ==========================================================
$Window.Add_Closed({
    $timer.Stop()
})

$timer.Start()
$Window.ShowDialog() | Out-Null
