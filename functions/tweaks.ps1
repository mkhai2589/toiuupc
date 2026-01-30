# ============================================================
# tweaks.ps1 - WINDOWS TWEAKS ENGINE (FULL FEATURES)
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# CORE TWEAK FUNCTIONS (KEEP ALL ORIGINAL LOGIC)
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
        if (-not (Test-Path $t.path)) {
            New-Item -Path $t.path -Force | Out-Null
            Write-Status "Tao registry path: $($t.path)" -Type 'INFO'
        }
        
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
        
        Stop-Service $t.serviceName -Force -ErrorAction SilentlyContinue
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
        if ($t.taskName) {
            Disable-ScheduledTask -TaskName $t.taskName -ErrorAction SilentlyContinue
            Write-Status "Task disabled: $($t.taskName)" -Type 'SUCCESS'
        }
        
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
    
    Write-Status "Tweak: $($t.name)" -Type 'INFO'
    Write-Host "  Category: $($t.category) | Level: $($t.level)" -ForegroundColor $global:UI_Colors.Label
    
    # Check OS compatibility
    if ($t.os_guard) {
        if (-not (Test-OSVersion -min $t.os_guard.min -max $t.os_guard.max)) {
            Write-Status "Khong tuong thich voi Windows hien tai" -Type 'WARNING'
            Write-Host "  Yeu cau: $($t.os_guard.min) to $($t.os_guard.max)" -ForegroundColor $global:UI_Colors.Label
            if ($t.os_guard.edition_note) {
                Write-Host "  Note: $($t.os_guard.edition_note)" -ForegroundColor $global:UI_Colors.Warning
            }
            return $false
        }
    }
    
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
    
    if ($t.reboot_required) {
        Write-Status "CAN KHOI DONG LAI MAY" -Type 'WARNING'
    }
    
    return $result
}

# ============================================================
# TWEAKS MENU (SIMPLE NUMBER SELECTION)
# ============================================================
function Show-TweaksMenu {
    param($Config)
    
    if (-not $Config.tweaks) {
        Write-Status "Cau hinh tweaks.json khong hop le!" -Type 'ERROR'
        Pause
        return
    }
    
    while ($true) {
        # Build menu items from tweaks
        $menuItems = @()
        $index = 1
        
        foreach ($tweak in $Config.tweaks) {
            $menuItems += @{ 
                Key = "$index"; 
                Text = "$($tweak.name.PadRight(40).Substring(0, 40))"
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
            Write-Status "Dang ap dung tweak..." -Type 'INFO'
            Write-Host " Name: $($selectedTweak.name)" -ForegroundColor $global:UI_Colors.Value
            Write-Host " Desc: $($selectedTweak.description)" -ForegroundColor $global:UI_Colors.Label
            Write-Host ""
            
            $success = Execute-Tweak -t $selectedTweak
            
            Write-Host ""
            if ($success) {
                Write-Status "Hoan thanh!" -Type 'SUCCESS'
            } else {
                Write-Status "Co loi xay ra!" -Type 'ERROR'
            }
            
            Pause
        } else {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
