# tweaks.ps1 - Tweaks menu (fixed "$cat:" syntax)

function Invoke-TweaksMenu {
    $tweaksJson = Get-Content "$PSScriptRoot\..\config\tweaks.json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
    if (-not $tweaksJson) {
        Write-Host "Không tìm thấy tweaks.json" -ForegroundColor Yellow
        return
    }

    $tweaks = @{}
    foreach ($category in $tweaksJson.PSObject.Properties.Name) {
        $tweaks[$category] = $tweaksJson.$category
    }

    Write-Host "Available Tweaks:" -ForegroundColor Cyan
    foreach ($cat in $tweaks.Keys) {
        Write-Host "$cat`: " -ForegroundColor Yellow
        foreach ($t in $tweaks[$cat]) { Write-Host " - $($t.Name)" }
    }

    Write-Host "`nChọn tweaks (comma separated names):" -ForegroundColor Cyan
    $selected = Read-Host
    $selectedTweaks = @{}
    foreach ($sel in $selected.Split(',').Trim()) {
        foreach ($cat in $tweaks.Keys) {
            $match = $tweaks[$cat] | Where-Object Name -eq $sel
            if ($match) { $selectedTweaks[$sel] = $match }
        }
    }

    if ($selectedTweaks.Count -gt 0) {
        Create-RestorePoint
        foreach ($tweakName in $selectedTweaks.Keys) {
            $tweak = $selectedTweaks[$tweakName]
            try {
                # Thực thi action (bạn cần map action thành lệnh thật)
                Write-Host "Applying: $tweakName" -ForegroundColor Green
                # Ví dụ: Invoke-Expression $tweak.Action (không khuyến khích, thay bằng switch nếu có thể)
            } catch {
                Write-Host "Error applying $tweakName: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No tweaks selected" -ForegroundColor Yellow
    }
}