# ============================================================
# tweaks.ps1 - WINDOWS TWEAKS ENGINE (FULL FEATURES)
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# CORE TWEAK FUNCTIONS
# ============================================================

function Test-OSVersion {
    param([string]$min, [string]$max)
    
    $os = [System.Environment]::OSVersion.Version
    $current = "$($os.Major).$($os.Minor)"
    
    try {
        $currentVer = [version]$current
        $minVer = [version]$min
        $maxVer = [version]$max
        
        return ($currentVer -ge $minVer -and $currentVer -le $maxVer)
    } catch {
        return $false
    }
}

function Apply-RegistryTweak {
    param($t)
    
    try {
        # Tạo registry path nếu không tồn tại
        if (-not (Test-Path $t.path)) {
            New-Item -Path $t.path -Force | Out-Null
            Write-Status "Tao registry path: $($t.path)" -Type 'INFO'
        }
        
        # Đặt giá trị registry
        Set-ItemProperty -Path $t.path -Name $t.nameReg -Value $t.value -Type $t.regType -Force
        Write-Status "Set registry: $($t.nameReg) = $($t.value)" -Type 'SUCCESS'
        return $true
    } catch {
        Write-Status "Registry error: $_" -Type 'ERROR'
        return $false
    }
}

function Apply-ServiceTweak {
    param($t)
    
    try {
        $svc = Get-Service -Name $t.serviceName -ErrorAction SilentlyContinue
        if (-not $svc) {
            Write-Status "Service not found: $($t.serviceName)" -Type 'WARNING'
            return $true
        }
        
        # Dừng service nếu đang chạy
        Stop-Service $t.serviceName -Force -ErrorAction SilentlyContinue
        
        # Đặt startup type
        Set-Service -Name $t.serviceName -StartupType $t.startup
        Write-Status "Service configured: $($t.serviceName) -> $($t.startup)" -Type 'SUCCESS'
        
        return $true
    } catch {
        Write-Status "Service error: $_" -Type 'ERROR'
        return $false
    }
}

function Apply-ScheduledTaskTweak {
    param($t)
    
    try {
        # Vô hiệu hóa task theo tên
        if ($t.taskName) {
            Disable-ScheduledTask -TaskName $t.taskName -ErrorAction SilentlyContinue
            Write-Status "Task disabled: $($t.taskName)" -Type 'SUCCESS'
        }
        
        # Vô hiệu hóa nhiều tasks
        if ($t.tasks) {
            foreach ($task in $t.tasks) {
                Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
                Write-Status "Task disabled: $task" -Type 'SUCCESS'
            }
        }
        
        return $true
    } catch {
        Write-Status "Task error: $_" -Type 'ERROR'
        return $false
    }
}

function Rollback-RegistryTweak {
    param($t)
    
    try {
        if ($t.rollback.value -ne $null) {
            Set-ItemProperty -Path $t.path -Name $t.nameReg -Value $t.rollback.value -Type $t.regType -Force
            Write-Status "Rollback registry: $($t.nameReg) = $($t.rollback.value)" -Type 'INFO'
        }
        return $true
    } catch {
        Write-Status "Rollback error: $_" -Type 'ERROR'
        return $false
    }
}

function Execute-Tweak {
    param($t, [switch]$Rollback = $false)
    
    # Hiển thị thông tin chi tiết về tweak
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

# ============================================================
# TWEAKS MENU
# ============================================================

function Show-TweaksMenu {
    param($Config)
    
    if (-not $Config.tweaks) {
        Write-Status "Cau hinh tweaks.json khong hop le!" -Type 'ERROR'
        Pause
        return
    }
    
    while ($true) {
        # Xây dựng menu items từ tweaks
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
        
        # Hiển thị menu với hai cột
        Show-Menu -MenuItems $menuItems -Title "WINDOWS TWEAKS" -TwoColumn -Prompt "Chon tweak de ap dung (0 de quay lai): "
        
        $choice = Read-Host
        
        if ($choice -eq "0") {
            return
        }
        
        $tweakIndex = [int]$choice - 1
        if ($tweakIndex -ge 0 -and $tweakIndex -lt $Config.tweaks.Count) {
            $selectedTweak = $Config.tweaks[$tweakIndex]
            
            # Hiển thị header
            Show-Header -Title "AP DUNG TWEAK"
            
            # Thực thi tweak
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

# ============================================================
# TWEAK UTILITIES
# ============================================================

function Get-TweakCount {
    param($Config)
    
    if (-not $Config.tweaks) {
        return 0
    }
    return $Config.tweaks.Count
}

function Show-TweakCategories {
    param($Config)
    
    if (-not $Config.tweaks) {
        Write-Host "Khong co tweak nao" -ForegroundColor Yellow
        return
    }
    
    $categories = @{}
    foreach ($tweak in $Config.tweaks) {
        $category = $tweak.category
        if (-not $categories.ContainsKey($category)) {
            $categories[$category] = 0
        }
        $categories[$category]++
    }
    
    Write-Host "`nDANH SACH CATEGORY TWEAKS:" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    
    foreach ($category in $categories.Keys | Sort-Object) {
        $count = $categories[$category]
        Write-Host "  $category : $count tweaks" -ForegroundColor White
    }
    
    Write-Host ""
}

function Test-AllTweaksCompatibility {
    param($Config)
    
    if (-not $Config.tweaks) {
        Write-Status "Khong co tweak de kiem tra" -Type 'WARNING'
        return
    }
    
    $compatible = 0
    $incompatible = 0
    
    foreach ($tweak in $Config.tweaks) {
        if ($tweak.os_guard) {
            if (Test-OSVersion -min $tweak.os_guard.min -max $tweak.os_guard.max) {
                $compatible++
            } else {
                $incompatible++
            }
        } else {
            $compatible++
        }
    }
    
    Write-Host "`nKET QUA KIEM TRA TUONG THICH:" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "  Tuong thich: $compatible tweaks" -ForegroundColor Green
    Write-Host "  Khong tuong thich: $incompatible tweaks" -ForegroundColor Yellow
    Write-Host "  Tong so: $($Config.tweaks.Count) tweaks" -ForegroundColor White
    Write-Host ""
}

# ============================================================
# EXPORT FUNCTIONS
# ============================================================

Export-ModuleMember -Function @(
    'Test-OSVersion',
    'Apply-RegistryTweak',
    'Apply-ServiceTweak',
    'Apply-ScheduledTaskTweak',
    'Rollback-RegistryTweak',
    'Execute-Tweak',
    'Show-TweaksMenu',
    'Get-TweakCount',
    'Show-TweakCategories',
    'Test-AllTweaksCompatibility'
)
