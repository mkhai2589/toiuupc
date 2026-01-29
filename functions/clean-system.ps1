function Invoke-CleanSystem {
    try {
        Write-Host "Đang dọn dẹp file tạm..." -ForegroundColor Cyan
        Remove-Item -Path "$env:TEMP\*", "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "Dọn dẹp hoàn tất!" -ForegroundColor Green
    } catch {
        Write-Host "Lỗi: $($_.Exception.Message)" -ForegroundColor Red
    }
}