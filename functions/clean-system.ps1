Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==========================================================
# MAIN ENTRY (WINUTIL STYLE + PROGRESS)
# ==========================================================
function Invoke-CleanSystem {

    Write-Host "`n🧹 Dang don dep he thong..." -ForegroundColor Cyan
    Write-CleanLog "=== CLEAN START ==="

    $beforeMB = Get-FreeSpaceMB
    Write-CleanLog "Free space before: $beforeMB MB"

    $steps = @(
        "Temp",
        "Windows Update",
        "System Logs",
        "Event Logs",
        "Recycle Bin",
        "Browser Cache",
        "Shader Cache",
        "Delivery Optimization",
        "Defender Cache",
        "WinSxS"
    )

    $total = $steps.Count
    $current = 0

    function Update-Progress {
        param([string]$Activity)
        $percent = [Math]::Round(($current / $total) * 100)
        Write-Progress `
            -Activity "Dang don dep he thong" `
            -Status $Activity `
            -PercentComplete $percent
    }

    # =====================
    $current++; Update-Progress "Dang don TEMP"
    Clean-Temp

    $current++; Update-Progress "Dang don Windows Update"
    Clean-WindowsUpdate

    $current++; Update-Progress "Dang don System Logs"
    Clean-SystemLogs

    $current++; Update-Progress "Dang xoa Event Logs"
    Clean-EventLogs

    $current++; Update-Progress "Dang don Recycle Bin"
    Clean-Recycle

    $current++; Update-Progress "Dang don Browser Cache"
    Clean-BrowserCache

    $current++; Update-Progress "Dang don Shader Cache"
    Clean-ShaderCache

    $current++; Update-Progress "Dang don Delivery Optimization"
    Clean-DeliveryOptimization

    $current++; Update-Progress "Dang don Defender Cache"
    Clean-DefenderCache

    $current++; Update-Progress "Dang toi uu WinSxS"
    Clean-WinSxS

    Write-Progress -Activity "Hoan tat" -Completed

    # =====================
    $afterMB = Get-FreeSpaceMB
    Write-CleanLog "Free space after: $afterMB MB"

    $freedMB = [Math]::Round(($afterMB - $beforeMB), 2)
    Write-CleanLog "Freed space: $freedMB MB"
    Write-CleanLog "=== CLEAN END ==="

    if ($freedMB -gt 1024) {
        $freedGB = [Math]::Round($freedMB / 1024, 2)
        Write-Host "✅ Da don duoc: $freedGB GB" -ForegroundColor Green
    } else {
        Write-Host "✅ Da don duoc: $freedMB MB" -ForegroundColor Green
    }
}

# ==========================================================
# MENU WRAPPER (FIX FOR MAIN APP)
# ==========================================================
function Invoke-CleanMenu {
    Invoke-CleanSystem
}
