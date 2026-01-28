function Install-SelectedApps {
    if (!(Test-Winget)) {
        Write-Host "⚠️ Winget not installed. Install from MS Store." -ForegroundColor Red
        return
    }

    $appsJson = Get-Content "$PSScriptRoot\..\config\applications.json" -Raw | ConvertFrom-Json
    $apps = @{}
    foreach ($category in $appsJson.PSObject.Properties.Name) {
        $apps[$category] = $appsJson.$category
    }

    # For console: List and select
    if (!$global:SelectedApps -or $global:SelectedApps.Count -eq 0) {
        Write-Host "Chọn apps (comma separated IDs, e.g. Brave.Brave,Discord.Discord):"
        $selected = Read-Host
        $global:SelectedApps = $selected.Split(',') | % { $_.Trim() } | ? { $_ }
    }

    foreach ($appId in $global:SelectedApps) {
        try {
            winget install --id $appId --silent --accept-package-agreements --accept-source-agreements
            Write-Host "✅ Installed: $appId" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error: $_" -ForegroundColor Red
        }
    }
}
