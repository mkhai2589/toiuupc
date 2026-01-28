function Install-SelectedApps {
    if (!(Test-Winget)) { Write-Host "⚠️ Winget not installed." -ForegroundColor Red; return }

    # Load config
    $appsJson = Get-Content "$PSScriptRoot\..\config\applications.json" -Raw | ConvertFrom-Json
    $apps = @{}
    foreach ($category in $appsJson.PSObject.Properties.Name) {
        $apps[$category] = $appsJson.$category
    }

    # GUI/Console selection (tích hợp với GUI cũ)
    # ... (logic chọn apps từ $global:SelectedApps hoặc console input)

    foreach ($appId in $selectedApps) {
        try {
            winget install --id $appId --silent --accept-package-agreements --accept-source-agreements
            Write-Host "✅ Installed $appId" -ForegroundColor Green
        } catch { Write-Host "❌ Error installing $appId: $_" -ForegroundColor Red }
    }
}
