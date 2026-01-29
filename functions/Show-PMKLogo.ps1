function Show-PMKLogo {

    [Console]::OutputEncoding = [System.Text.Encoding]::ASCII
    $OutputEncoding = [System.Text.Encoding]::ASCII

    # ===== LOGO ASCII (KHÔNG MÉO) =====
    $logo = @(
        "PPPPPP  MM    MM  KK   KK   TTTTTT   OOOOO   OOOOO   LL",
        "PP   PP MMM  MMM  KK  KK      TT    OO   OO OO   OO  LL",
        "PPPPPP  MM MM MM  KKKKK       TT    OO   OO OO   OO  LL",
        "PP      MM    MM  KK  KK      TT    OO   OO OO   OO  LL",
        "PP      MM    MM  KK   KK     TT     OOOOO   OOOOO   LLLLL",
        "",
        "Author : MINH KHAI - 0333090930",
        "PMK TOOLBOX - Toi Uu Windows"
    )

    # ===== TÍNH TOÁN SCALE THEO WIDTH =====
    $consoleWidth = [Console]::WindowWidth
    $maxLineLength = ($logo | Measure-Object Length -Maximum).Maximum

    # Padding trong khung (co giãn theo màn hình)
    $innerPadding = [Math]::Max(2, [Math]::Min(10, ($consoleWidth - $maxLineLength) / 4))
    $frameWidth = $maxLineLength + ($innerPadding * 2)

    if ($frameWidth -gt ($consoleWidth - 2)) {
        $frameWidth = $consoleWidth - 2
        $innerPadding = [Math]::Max(1, ($frameWidth - $maxLineLength) / 2)
    }

    $leftPad = [Math]::Max(0, ($consoleWidth - ($frameWidth + 2)) / 2)

    # ===== VẼ KHUNG TRÊN =====
    Write-Host (" " * $leftPad + "+" + ("=" * $frameWidth) + "+") -ForegroundColor DarkGray

    # ===== VẼ NỘI DUNG =====
    foreach ($line in $logo) {
        $spaceRight = $frameWidth - ($innerPadding * 2) - $line.Length
        if ($spaceRight -lt 0) { $spaceRight = 0 }

        Write-Host (" " * $leftPad + "|") -NoNewline -ForegroundColor DarkGray
        Write-Host (" " * $innerPadding) -NoNewline

        # ---- MÀU ----
        if ($line -like "PP*") {
            Write-Host $line -NoNewline -ForegroundColor Cyan
        }
        elseif ($line -like "Author*") {
            Write-Host $line -NoNewline -ForegroundColor Yellow
        }
        elseif ($line -like "PMK TOOLBOX*") {
            Write-Host $line -NoNewline -ForegroundColor Green
        }
        else {
            Write-Host $line -NoNewline
        }

        Write-Host (" " * ($innerPadding + $spaceRight)) -NoNewline
        Write-Host "|" -ForegroundColor DarkGray
    }

    # ===== VẼ KHUNG DƯỚI =====
    Write-Host (" " * $leftPad + "+" + ("=" * $frameWidth) + "+") -ForegroundColor DarkGray
}
