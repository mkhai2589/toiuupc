# tweaks.ps1 - Quản lý và áp dụng tweaks an toàn (tối ưu, không dùng Invoke-Expression)

function Invoke-TweaksMenu {
    [CmdletBinding()]
    param()

    # Kiểm tra quyền Admin (tweaks cần quyền cao)
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Cần chạy với quyền Administrator để áp dụng tweaks!" -ForegroundColor Red
        return
    }

    # Load config
    $jsonPath = "$PSScriptRoot\..\config\tweaks.json"
    if (-not (Test-Path $jsonPath)) {
        Write-Host "Không tìm thấy file tweaks.json" -ForegroundColor Yellow
        return
    }

    try {
        $tweaksJson = Get-Content $jsonPath -Raw -ErrorAction Stop | ConvertFrom-Json
    } catch {
        Write-Host "Lỗi đọc tweaks.json: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # Xây dựng danh sách tweaks theo category
    $tweaksByCategory = @{}
    foreach ($category in $tweaksJson.PSObject.Properties.Name) {
        $tweaksByCategory[$category] = $tweaksJson.$category
    }

    # Hiển thị danh sách
    Clear-Host
    Write-Host "DANH SÁCH TWEAKS CÓ SẴN" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor DarkGray

    $allTweaks = @{}
    $index = 1
    foreach ($category in $tweaksByCategory.Keys) {
        Write-Host "`n$category" -ForegroundColor Yellow
        Write-Host ("-" * $category.Length) -ForegroundColor DarkGray

        foreach ($tweak in $tweaksByCategory[$category]) {
            $tweak | Add-Member -NotePropertyName "Index" -NotePropertyValue $index -Force
            $allTweaks[$index] = $tweak
            Write-Host " [$index] $($tweak.Name)" -ForegroundColor White
            $index++
        }
    }

    Write-Host "`nHướng dẫn:" -ForegroundColor Cyan
    Write-Host " - Nhập số (ví dụ: 1,3,5-8) để chọn tweak"
    Write-Host " - Nhập 'all' để áp dụng tất cả"
    Write-Host " - Nhập 'r' để revert (nếu có)"
    Write-Host " - Nhấn ESC để thoát" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "Lựa chọn của bạn: " -NoNewline -ForegroundColor Cyan
    $choice = Read-Host

    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Escape) { return }
    }

    $selectedIndices = @()

    if ($choice -eq 'all') {
        $selectedIndices = 1..($index-1)
    } elseif ($choice -eq 'r') {
        Write-Host "Chức năng revert chưa được triển khai đầy đủ." -ForegroundColor Yellow
        return
    } else {
        foreach ($part in $choice.Split(',')) {
            $part = $part.Trim()
            if ($part -match '^(\d+)-(\d+)$') {
                $start = [int]$Matches[1]
                $end   = [int]$Matches[2]
                $selectedIndices += $start..$end
            } elseif ($part -match '^\d+$') {
                $selectedIndices += [int]$part
            }
        }
    }

    $selectedTweaks = $selectedIndices | Where-Object { $allTweaks.ContainsKey($_) } | ForEach-Object { $allTweaks[$_] }

    if ($selectedTweaks.Count -eq 0) {
        Write-Host "Không có tweak nào được chọn." -ForegroundColor Yellow
        return
    }

    # Xác nhận trước khi áp dụng
    Write-Host "`nBạn sắp áp dụng $($selectedTweaks.Count) tweak sau:" -ForegroundColor Cyan
    $selectedTweaks | ForEach-Object { Write-Host " - $($_.Name)" }
    Write-Host "`nTiếp tục? (Y/N): " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host
    if ($confirm -notmatch '^[yY]$') { Write-Host "Đã hủy." -ForegroundColor Yellow; return }

    # Tạo điểm khôi phục (nếu hàm tồn tại từ utils.ps1)
    if (Get-Command Create-RestorePoint -ErrorAction SilentlyContinue) {
        Create-RestorePoint
    } else {
        Write-Host "Không tìm thấy Create-RestorePoint, bỏ qua điểm khôi phục." -ForegroundColor Yellow
    }

    # Áp dụng từng tweak
    foreach ($tweak in $selectedTweaks) {
        Write-Host "`nĐang áp dụng: $($tweak.Name)" -ForegroundColor Cyan

        try {
            # Thay vì Invoke-Expression nguy hiểm, dùng switch/map action
            switch -Regex ($tweak.Name) {
                "Tạo điểm khôi phục"            { Create-RestorePoint }
                "Xóa file tạm"                   { Remove-Item -Path "$env:TEMP\*", "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue }
                "Vô hiệu hóa Telemetry"          { Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -CreatePath }
                # Thêm mapping cho các tweak khác từ tweaks.json (bạn mở rộng dần)
                "Tắt Cortana"                    { Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -CreatePath }
                "Xóa OneDrive"                   { taskkill /f /im OneDrive.exe; & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall }
                "Remove Edge"                    { Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue; winget uninstall Microsoft.Edge --silent }
                default {
                    Write-Host "Chưa hỗ trợ action cho tweak này: $($tweak.Name)" -ForegroundColor Yellow
                }
            }
            Write-Host "Hoàn tất: $($tweak.Name)" -ForegroundColor Green
        } catch {
            Write-Host "Lỗi khi áp dụng $($tweak.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "`nHoàn tất áp dụng tweaks!" -ForegroundColor Green
    Write-Host "Nhấn phím bất kỳ để quay lại menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}