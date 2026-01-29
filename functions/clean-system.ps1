function Invoke-CleanSystem {
    try {
        # Clean temp folders
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Disk Cleanup (auto mode)
        Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow

        # Empty Recycle Bin
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue

        Write-Host "✅ Hệ thống đã được dọn dẹp sạch sẽ!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Lỗi khi dọn dẹp: $($_.Exception.Message)" -ForegroundColor Red
    }
}