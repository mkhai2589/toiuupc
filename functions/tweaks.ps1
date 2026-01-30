# ============================================================
# tweaks.ps1 - WINDOWS TWEAKS ENGINE (FIXED DISPLAY)
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ... (giữ nguyên các hàm trước đó)

function Execute-Tweak {
    param($t, [switch]$Rollback = $false)
    
    Write-Host ""
    Write-Host " THONG TIN TWEAK:" -ForegroundColor $global:UI_Colors.Title
    Write-Host "   Ten: $($t.name)" -ForegroundColor $global:UI_Colors.Value
    Write-Host "   Mo ta: $($t.description)" -ForegroundColor $global:UI_Colors.Label
    Write-Host "   Loai: $($t.category) | Muc do: $($t.level)" -ForegroundColor $global:UI_Colors.Label
    Write-Host ""
    
    # Kiểm tra OS compatibility
    if ($t.os_guard) {
        if (-not (Test-OSVersion -min $t.os_guard.min -max $t.os_guard.max)) {
            Write-Status "Khong tuong thich voi Windows hien tai" -Type 'WARNING'
            Write-Host "   Yeu cau: $($t.os_guard.min) to $($t.os_guard.max)" -ForegroundColor $global:UI_Colors.Label
            if ($t.os_guard.edition_note) {
                Write-Host "   Ghi chu: $($t.os_guard.edition_note)" -ForegroundColor $global:UI_Colors.Warning
            }
            Write-Host ""
            return $false
        }
    }
    
    Write-Status "Dang ap dung tweak..." -Type 'INFO'
    Write-Host ""
    
    $result = $false
    if ($Rollback) {
        switch ($t.type) {
            "registry" { $result = Rollback-RegistryTweak $t }
            default { Write-Status "Rollback chua duoc ho tro cho loai: $($t.type)" -Type 'WARNING' }
        }
    } else {
        switch ($t.type) {
            "registry"        { $result = Apply-RegistryTweak $t }
            "service"         { $result = Apply-ServiceTweak $t }
            "scheduled_task"  { $result = Apply-ScheduledTaskTweak $t }
            default { Write-Status "Khong ho tro loai tweak: $($t.type)" -Type 'ERROR' }
        }
    }
    
    Write-Host ""
    if ($t.reboot_required) {
        Write-Status "CAN KHOI DONG LAI MAY" -Type 'WARNING'
    }
    
    Write-Host ""
    return $result
}

# Hàm menu chính cũng cần sửa
function Show-TweaksMenu {
    param($Config)
    
    if (-not $Config.tweaks) {
        Write-Status "Cau hinh tweaks.json khong hop le!" -Type 'ERROR'
        Pause
        return
    }
    
    while ($true) {
        $menuItems = @()
        $index = 1
        
        foreach ($tweak in $Config.tweaks) {
            $displayName = $tweak.name
            if ($displayName.Length -gt 45) {
                $displayName = $displayName.Substring(0, 42) + "..."
            }
            
            $menuItems += @{ 
                Key = "$index"; 
                Text = "$displayName"
            }
            $index++
        }
        
        $menuItems += @{ Key = "0"; Text = "Quay lai Menu Chinh" }
        
        Show-Menu -MenuItems $menuItems -Title "WINDOWS TWEAKS" -TwoColumn -Prompt "Chon tweak de ap dung (0 de quay lai): "
        
        $choice = Read-Host
        
        if ($choice -eq "0") {
            return
        }
        
        $tweakIndex = [int]$choice - 1
        if ($tweakIndex -ge 0 -and $tweakIndex -lt $Config.tweaks.Count) {
            $selectedTweak = $Config.tweaks[$tweakIndex]
            
            Show-Header -Title "AP DUNG TWEAK"
            
            $success = Execute-Tweak -t $selectedTweak
            
            Write-Host ""
            if ($success) {
                Write-Status "Hoan thanh!" -Type 'SUCCESS'
            } else {
                Write-Status "Co loi xay ra!" -Type 'ERROR'
            }
            
            Write-Host ""
            Pause
        } else {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
