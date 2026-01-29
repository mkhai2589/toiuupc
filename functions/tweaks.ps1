function Invoke-Tweaks {
    param([hashtable]$SelectedTweaks)

    Create-RestorePoint
    foreach ($tweakName in $SelectedTweaks.Keys) {
        $tweak = $SelectedTweaks[$tweakName]
        try {
            # Thay eval bằng calls (map Action to functions)
            switch ($tweak.Action) {
                "Create-RestorePoint" { Create-RestorePoint }  # Đã có
                "Remove-TempFiles" { Remove-Item -Path $env:TEMP\* , C:\Windows\Temp\* -Recurse -Force -ErrorAction SilentlyContinue }
                "Disable-Telemetry" { Set-RegistryTweak -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -CreatePath; Set-RegistryTweak -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'AllowTelemetry' -Value 0 }
                "Disable-Services" { $services = @('DiagTrack', 'dmwappushservice', 'WMPNetworkSvc', 'RemoteRegistry'); foreach ($svc in $services) { Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service $svc -Force -ErrorAction SilentlyContinue } }
                # Thêm các switch cho tất cả Actions tương tự (từ tweaks.json)
                "Optimize-Power" { powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c; powercfg -h off }
                "Disable-Hibernation" { Set-RegistryTweak -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\Power' -Name 'HibernateEnabled' -Value 0 -CreatePath; powercfg /hibernate off }
                "Disable-Cortana" { Set-RegistryTweak -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -Value 0 -CreatePath }
                "Disable-Ads" { Set-RegistryTweak -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -CreatePath }
                "Disable-Location" { Set-RegistryTweak -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' -Name 'Value' -Value 'Deny' -Type 'String' -CreatePath }
                "Disable-Defender" { Set-RegistryTweak -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name 'DisableAntiSpyware' -Value 1 -CreatePath }  # Caution
                "Disable-ActivityHistory" { Set-RegistryTweak -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed' -Value 0 -CreatePath }
                "Enable-DarkMode" { Set-RegistryTweak -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value 0 }
                "Show-HiddenFiles" { Set-RegistryTweak -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value 1 }
                "Disable-Transparency" { Set-RegistryTweak -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0 }
                "Enable-NumLock" { Set-RegistryTweak -Path 'HKU:\.DEFAULT\Control Panel\Keyboard' -Name 'InitialKeyboardIndicators' -Value 2 -CreatePath }
                "Remove-OneDrive" { taskkill /f /im OneDrive.exe; & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall; Remove-Item "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue }
                "Remove-Bloatware" { $bloat = @('*Bing*', '*Cortana*', '*Xbox*'); foreach ($app in $bloat) { Remove-WindowsApp -Pattern $app } }
                "Disable-Tips" { Set-RegistryTweak -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338393Enabled' -Value 0 -CreatePath }
                "Disable-ConsumerFeatures" { Set-RegistryTweak -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Value 1 -CreatePath }
                "Disable-GameBar" { Set-RegistryTweak -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -CreatePath }
                "Disable-Notifications" { Set-RegistryTweak -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications' -Name 'ToastEnabled' -Value 0 }
                "Prefer-IPv4" { Set-RegistryTweak -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' -Name 'DisabledComponents' -Value 32 }
                "Disable-StorageSense" { Set-RegistryTweak -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' -Name '01' -Value 0 }
                "Set-UTCTime" { Set-RegistryTweak -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'RealTimeIsUniversal' -Value 1 -Type 'QWord' }
                "Disable-FullUpdates" { Set-Service wuauserv -StartupType Disabled; Stop-Service wuauserv; New-ScheduledTask -Action (New-ScheduledTaskAction -Execute 'powershell' -Argument 'Set-Service wuauserv -StartupType Disabled') -Trigger (New-ScheduledTaskTrigger -AtStartup) -TaskName 'PMKUpdateDisable' -Force }
                "Remove-Edge" { Stop-Process msedge -Force -ErrorAction SilentlyContinue; winget uninstall Microsoft.Edge --silent; Remove-Item "$env:ProgramFiles(x86)\Microsoft\Edge" -Recurse -Force -ErrorAction SilentlyContinue; icacls "$env:ProgramFiles(x86)\Microsoft\Edge" /deny 'SYSTEM:(OI)(F)' }
                "OOBE-Bypass" { $xml = '<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup"><OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens></OOBE></component></settings></unattend>'; $xml | Out-File 'C:\Windows\Panther\unattend.xml' -Encoding UTF8 }
                default { Write-Warning "Unknown action: $($tweak.Action)" }
            }
            Write-Host "✅ $tweakName applied" -ForegroundColor $SUCCESS_COLOR
        } catch {
            Write-Host "❌ $tweakName error: $_" -ForegroundColor $ERROR_COLOR
        }
    }
}

function Invoke-TweaksMenu {
    $tweaksJson = Get-Content "$PSScriptRoot\..\config\tweaks.json" -Raw | ConvertFrom-Json
    $tweaks = @{}
    foreach ($category in $tweaksJson.PSObject.Properties.Name) {
        $tweaks[$category] = $tweaksJson.$category
    }

    # List all for selection
    Write-Host "Available Tweaks:"
    foreach ($cat in $tweaks.Keys) {
        Write-Host "$cat:"
        foreach ($t in $tweaks[$cat]) { Write-Host " - $($t.Name)" }
    }

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
    if ($selectedTweaks.Count -gt 0) { Invoke-Tweaks -SelectedTweaks $selectedTweaks }
    else { Write-Warning "No tweaks selected!" }
}