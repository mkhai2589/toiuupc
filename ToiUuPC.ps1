# ==================================================
# ToiUuPC.ps1 - FINAL INTEGRATED VERSION
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==================================================
# RESOLVE SCRIPT ROOT (SAFE)
# ==================================================
if ($PSScriptRoot) {
    $ROOT = $PSScriptRoot
}
elseif ($MyInvocation.MyCommand.Path) {
    $ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
}
else {
    $ROOT = Get-Location
}

Set-Location $ROOT

# ==================================================
# PATHS (MATCH PROJECT STRUCTURE)
# ==================================================
$CFG  = Join-Path $ROOT "config"
$FUNC = Join-Path $ROOT "functions"
$UI   = Join-Path $ROOT "ui"
$LOG  = Join-Path $ROOT "runtime\logs"

# ==================================================
# VALIDATE FOLDERS
# ==================================================
foreach ($p in @($CFG, $FUNC, $UI)) {
    if (-not (Test-Path $p)) {
        Write-Host "Missing required path: $p" -ForegroundColor Red
        exit 1
    }
}

# ==================================================
# LOAD FUNCTIONS
# ==================================================
Get-ChildItem $FUNC -Filter *.ps1 -File |
    Sort-Object Name |
    ForEach-Object {
        . $_.FullName
    }

# ==================================================
# INIT + ADMIN
# ==================================================
Initialize-ToiUuPCEnvironment
Ensure-Admin

# ==================================================
# DASHBOARD (WPF PERFORMANCE OVERLAY)
# ==================================================
function Show-Dashboard {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    $XamlPath = Join-Path $UI "Dashboard.xaml"
    if (-not (Test-Path $XamlPath)) {
        Write-Host "Dashboard.xaml not found" -ForegroundColor Red
        return
    }

    [xml]$xaml = Get-Content $XamlPath -Raw
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $Window = [Windows.Markup.XamlReader]::Load($reader)

    # ============================
    # BIND CONTROLS
    # ============================
    $CpuRing  = $Window.FindName("CpuRing")
    $CpuText  = $Window.FindName("CpuText")
    $CpuBar   = $Window.FindName("CpuBar")
    $RamBar   = $Window.FindName("RamBar")
    $RamText  = $Window.FindName("RamText")
    $DiskBar  = $Window.FindName("DiskBar")
    $DiskText = $Window.FindName("DiskText")
    $DiskWarn = $Window.FindName("DiskWarn")

    # ============================
    # PERFORMANCE COUNTERS
    # ============================
    $cpuCounter = New-Object Diagnostics.PerformanceCounter(
        "Processor", "% Processor Time", "_Total"
    )
    $null = $cpuCounter.NextValue()

    # ============================
    # HELPER FUNCTIONS
    # ============================
    function Set-BarColor($bar, [int]$percent) {
        if ($percent -ge 80) { $bar.Foreground = "Red" }
        elseif ($percent -ge 60) { $bar.Foreground = "Gold" }
        else { $bar.Foreground = "LimeGreen" }
    }

    # ============================
    # CPU RING GEOMETRY
    # ============================
    $centerX = 65
    $centerY = 65
    $radius  = 55

    $arc = New-Object Windows.Media.ArcSegment
    $arc.Size = New-Object Windows.Size($radius, $radius)
    $arc.SweepDirection = "Clockwise"

    $figure = New-Object Windows.Media.PathFigure
    $figure.StartPoint = New-Object Windows.Point($centerX, $centerY - $radius)
    $figure.Segments.Add($arc)

    $geometry = New-Object Windows.Media.PathGeometry
    $geometry.Figures.Add($figure)
    $CpuRing.Data = $geometry

    function Update-CpuRing([int]$percent) {
        $angle = ($percent / 100) * 360
        $rad   = ($angle - 90) * [Math]::PI / 180

        $arc.Point = New-Object Windows.Point(
            $centerX + $radius * [Math]::Cos($rad),
            $centerY + $radius * [Math]::Sin($rad)
        )
        $arc.IsLargeArc = $angle -gt 180
    }

    # ============================
    # UPDATE TIMER
    # ============================
    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(1000)

    $timer.Add_Tick({

        # CPU
        $cpu = [Math]::Round($cpuCounter.NextValue(), 0)
        $CpuText.Text = "$cpu%"
        $CpuBar.Value = $cpu
        Set-BarColor $CpuBar $cpu
        Update-CpuRing $cpu

        # RAM
        $os = Get-CimInstance Win32_OperatingSystem
        $used = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
        $ramPercent = [Math]::Round(($used / $os.TotalVisibleMemorySize) * 100, 0)
        $RamBar.Value = $ramPercent
        $RamText.Text = "$ramPercent%"
        Set-BarColor $RamBar $ramPercent

        # DISK
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $diskPercent = [Math]::Round(
            (($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 0
        )
        $DiskBar.Value = $diskPercent
        $DiskText.Text = "$diskPercent% used"
        Set-BarColor $DiskBar $diskPercent
        $DiskWarn.Visibility = if ($diskPercent -ge 85) { "Visible" } else { "Collapsed" }

    })

    $Window.Add_Closed({ $timer.Stop() })
    $timer.Start()
    $Window.ShowDialog() | Out-Null
}

# ==================================================
# MAIN MENU
# ==================================================
function Show-MainMenu {
    Clear-Host
    Show-PMKLogo
    Write-Host ""
    Write-Host "1. Apply Windows Tweaks"
    Write-Host "2. Install Applications"
    Write-Host "3. DNS Management"
    Write-Host "4. Clean System"
    Write-Host "5. Create Restore Point"
    Write-Host "6. Performance Dashboard"
    Write-Host "0. Exit"
    Write-Host ""
}

# ==================================================
# MAIN LOOP
# ==================================================
do {
    Show-MainMenu
    $c = Read-Host "Chon"

    switch ($c) {

        "1" {
            $path = Join-Path $CFG "tweaks.json"
            if (Test-Path $path) {
                $cfg = Get-Content $path -Raw | ConvertFrom-Json
                Invoke-TweaksMenu -Config $cfg
            } else {
                Write-Host "Không tìm thấy tweaks.json" -ForegroundColor Red
            }
            pause
        }

        "2" {
            $path = Join-Path $CFG "applications.json"
            if (Test-Path $path) {
                $cfg = Get-Content $path -Raw | ConvertFrom-Json
                Invoke-AppMenu -Config $cfg
            } else {
                Write-Host "Không tìm thấy applications.json" -ForegroundColor Red
            }
            pause
        }

        "3" {
            $path = Join-Path $CFG "dns.json"
            if (Test-Path $path) {
                Invoke-DnsMenu -ConfigPath $path
            } else {
                Write-Host "Không tìm thấy dns.json" -ForegroundColor Red
            }
            pause
        }

        "4" {
            Invoke-CleanMenu
            pause
        }

        "5" {
            New-RestorePoint
            pause
        }

        "6" {
            Show-Dashboard
        }

        "0" {
            break
        }

        default {
            Write-Host "Lựa chọn không hợp lệ"
            Start-Sleep 1
        }
    }

} while ($true)
