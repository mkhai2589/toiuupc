function Install-AppsQuick {
    Reset-ConsoleStyle
    Show-PMKLogo
    Show-SystemHeader

    Write-Host "DANH SÁCH ỨNG DỤNG CÓ THỂ CÀI NHANH" -ForegroundColor $HEADER_COLOR
    Write-Host "====================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""

    foreach ($category in $AppCategories.Keys) {
        $apps = $AppCategories[$category]
        Write-Host $category -ForegroundColor $HEADER_COLOR
        Write-Host "------------------------------------" -ForegroundColor $BORDER_COLOR

        $half = [Math]::Ceiling($apps.Count / 2)
        for ($j = 0; $j -lt $half; $j++) {
            $app1 = $apps[$j]
            $app2 = if ($j + $half -lt $apps.Count) { $apps[$j + $half] } else { $null }

            $line1 = " [$($app1.STT)] $($app1.Name.PadRight(35))"
            $line2 = if ($app2) { " [$($app2.STT)] $($app2.Name.PadRight(35))" } else { "" }

            Write-Host $line1 -NoNewline -ForegroundColor $HEADER_COLOR
            if ($app2) {
                Write-Host "  " -NoNewline
                Write-Host $line2 -ForegroundColor $HEADER_COLOR
            } else {
                Write-Host ""
            }
        }
        Write-Host ""
        Write-Host ""
        Write-Host ""
    }

    Write-Host "====================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host "Hướng dẫn:" -ForegroundColor $TEXT_COLOR
    Write-Host " - Nhập STT (ví dụ: 1,4,7) hoặc Winget ID" -ForegroundColor $TEXT_COLOR
    Write-Host " - Nhấn ESC để thoát" -ForegroundColor $TEXT_COLOR
    Write-Host ""

    Write-Host "Nhập lựa chọn: " -NoNewline -ForegroundColor $HEADER_COLOR
    $input = Read-Host

    if ([Console]::KeyAvailable -and [Console]::ReadKey($true).Key -eq "Escape") {
        Write-Host "`nThoát..." -ForegroundColor $BORDER_COLOR
        return
    }

    $items = $input.Split(',').Trim()
    $success = 0
    $fail = 0

    foreach ($item in $items) {
        $app = $null
        if ($item -match '^\d+$') {
            foreach ($cat in $AppCategories.Values) {
                $app = $cat | Where-Object { $_.STT -eq [int]$item }
                if ($app) { break }
            }
        }

        try {
            if ($app) {
                winget install --id $app.ID --silent --accept-package-agreements --accept-source-agreements
            } else {
                winget install --id $item --silent --accept-package-agreements --accept-source-agreements
            }
            $success++
        } catch {
            $fail++
        }
    }

    Write-Host "Kết quả: $success thành công, $fail thất bại" -ForegroundColor $(if ($fail -eq 0) { $SUCCESS_COLOR } else { $ERROR_COLOR })
    Write-Host "Nhấn phím bất kỳ để tiếp tục..." -ForegroundColor $HEADER_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
