function Install-SelectedApps {
    if (!(Test-Winget)) {
        Write-Host "⚠️ Winget not installed. Install from MS Store or 'winget install --id Microsoft.Winget.CLI'" -ForegroundColor Red
        return
    }

    # Load from config
    $appsJson = Get-Content "$PSScriptRoot\..\config\applications.json" -Raw | ConvertFrom-Json
    $apps = @{}
    foreach ($category in $appsJson.PSObject.Properties.Name) {
        $apps[$category] = $appsJson.$category
    }

    # For console fallback
    if (!$global:SelectedApps) {
        $global:SelectedApps = @{}
        Write-Host "Enter app Winget IDs to install (comma separated, e.g. Brave.Brave,Discord.Discord):"
        $input = Read-Host
        foreach ($id in $input.Split(',')) {
            $global:SelectedApps[$id.Trim()] = $true
        }
    }

    if ($global:SelectedApps.Count -eq 0) {
        Write-Host "No apps selected." -ForegroundColor Yellow
        return
    }

    Write-Host "Installing $($global:SelectedApps.Count) apps..." -ForegroundColor Yellow
    foreach ($appId in $global:SelectedApps.Keys) {
        try {
            winget install --id $appId --silent --accept-package-agreements --accept-source-agreements
            Write-Host "✅ Installed: $appId" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error installing $appId: $_" -ForegroundColor Red
        }
    }
    Write-Host "Install complete. Restart if needed." -ForegroundColor Green
}
