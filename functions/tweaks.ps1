function Invoke-Tweaks {
    param([hashtable]$SelectedTweaks)

    Create-RestorePoint
    foreach ($tweakName in $SelectedTweaks.Keys) {
        $tweak = $SelectedTweaks[$tweakName]
        try {
            & $tweak.Action
            Write-Host "✅ $tweakName applied" -ForegroundColor Green
        } catch {
            Write-Host "❌ $tweakName error: $_" -ForegroundColor Red
        }
    }
}

function Invoke-TweaksMenu {
    $tweaksJson = Get-Content "$PSScriptRoot\..\config\tweaks.json" -Raw | ConvertFrom-Json
    $tweaks = @{}
    foreach ($category in $tweaksJson.PSObject.Properties.Name) {
        $tweaks[$category] = $tweaksJson.$category
    }

    # For console: List and select
    Write-Host "Chọn tweaks (comma separated names, e.g. Vô hiệu hóa Telemetry,Tắt Cortana):"
    $selected = Read-Host
    $selectedTweaks = @{}
    foreach ($sel in $selected.Split(',')) {
        $sel = $sel.Trim()
        foreach ($cat in $tweaks.Keys) {
            $match = $tweaks[$cat] | Where-Object Name -eq $sel
            if ($match) { $selectedTweaks[$sel] = $match }
        }
    }
    Invoke-Tweaks -SelectedTweaks $selectedTweaks
}
