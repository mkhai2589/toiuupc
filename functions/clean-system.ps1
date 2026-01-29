# clean-system.ps1 - System cleanup (fixed - no YAML)

function Invoke-CleanSystem {
    try {
        Write-Host "Đang dọn dẹp file tạm..." -ForegroundColor Cyan

        # Temp folders
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Disk Cleanup
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow

        # Recycle Bin
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue

        Write-Host "Dọn dẹp hoàn tất!" -ForegroundColor $SUCCESS_COLOR
    } catch {
        Write-Host "Lỗi dọn dẹp: $($_.Exception.Message)" -ForegroundColor Red
    }
}