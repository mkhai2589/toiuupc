# ============================================================
# tweaks.ps1 - WINDOWS TWEAKS
# ============================================================

function Apply-Tweak {
    param($tweak)
    
    Write-Host ""
    Write-Host " AP DUNG TWEAK:" -ForegroundColor White
    Write-Host "   Ten: $($tweak.name)" -ForegroundColor Gray
    Write-Host "   Mo ta: $($tweak.description)" -ForegroundColor Gray
    Write-Host "   Muc do: $($tweak.level)" -ForegroundColor $(if ($tweak.level -eq "dangerous") { "Red" } else { "Yellow" })
    Write-Host ""
    
    if ($tweak.level -eq "dangerous") {
        Write-Host " CANH BAO: Tweak nay co the gay loi he thong!" -ForegroundColor Red
        Write-Host ""
        $confirm = Read-Host " Nhap 'YES' de tiep tuc: "
        if ($confirm -ne "YES") {
            Write-Status "Da huy!" -Type 'INFO'
            return $false
        }
    }
    
    $success = $false
    
    try {
        switch ($tweak.type) {
            "service" {
                if ($tweak.startup -eq "Disabled") {
                    Stop-Service $tweak.serviceName -Force -ErrorAction SilentlyContinue
                }
                Set-Service -Name $tweak.serviceName -StartupType $tweak.startup
                Write-Host "   Dich vu: $($tweak.serviceName) -> $($tweak.startup)" -ForegroundColor Green
                $success = $true
            }
            "registry" {
                if (-not (Test-Path $tweak.path)) {
                    New-Item -Path $tweak.path -Force | Out-Null
                }
                Set-ItemProperty -Path $tweak.path -Name $tweak.name -Value $tweak.value -Type $tweak.regType
                Write-Host "   Registry: $($tweak.path)\$($tweak.name)" -ForegroundColor Green
                $success = $true
            }
            "script" {
                Invoke-Expression $tweak.script
                Write-Host "   Script da chay thanh cong" -ForegroundColor Green
                $success = $true
            }
            "task" {
                foreach ($task in $tweak.tasks) {
                    Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
                    Write-Host "   Da vo hieu task: $task" -ForegroundColor Green
                }
                $success = $true
            }
        }
        
        if ($success) {
            Write-Status "Tweak da duoc ap dung!" -Type 'SUCCESS'
            
            if ($tweak.reboot_required) {
                Write-Host ""
                Write-Host " CAN KHOI DONG LAI MAY" -ForegroundColor Yellow
                Write-Host "   Thay doi se co hieu luc sau khi khoi dong lai." -ForegroundColor Gray
            }
            
            return $true
        }
        
    } catch {
        Write-Status "Loi khi ap dung tweak: $_" -Type 'ERROR'
        return $false
    }
}

function Show-TweaksMenu {
    param($Config)
    
    if (-not $Config -or -not $Config.tweaks) {
        Write-Status "Cau hinh tweaks khong hop le!" -Type 'ERROR'
        Pause
        return
    }
    
    while ($true) {
        Show-Header -Title "WINDOWS TWEAKS"
        
        Write-Host " DANH SACH TWEAKS:" -ForegroundColor White
        Write-Host ""
        
        $index = 1
        $tweakMap = @{}
        
        # Group by category
        $categories = @{}
        foreach ($tweak in $Config.tweaks) {
            $category = $tweak.category
            if (-not $categories.ContainsKey($category)) {
                $categories[$category] = @()
            }
            $categories[$category] += $tweak
        }
        
        foreach ($cat in ($categories.Keys | Sort-Object)) {
            Write-Host " [$cat]" -ForegroundColor Cyan
            Write-Host ""
            
            foreach ($tweak in $categories[$cat]) {
                $levelColor = switch ($tweak.level) {
                    "dangerous" { "Red" }
                    "balanced" { "Yellow" }
                    default { "Gray" }
                }
                
                Write-Host "   $index. $($tweak.name)" -ForegroundColor Gray
                Write-Host "      $($tweak.description)" -ForegroundColor DarkGray
                $tweakMap[$index] = $tweak
                $index++
                Write-Host ""
            }
        }
        
        Write-Host ("-" * $global:UI_Width) -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  [0] Quay lai Menu Chinh" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host " Chon tweak de ap dung (0 de quay lai): "
        
        if ($choice -eq "0") {
            return
        }
        
        if ($choice -match '^\d+$') {
            $tweakIndex = [int]$choice
            if ($tweakIndex -ge 1 -and $tweakIndex -lt $index) {
                $selectedTweak = $tweakMap[$tweakIndex]
                if ($selectedTweak) {
                    Show-Header -Title "AP DUNG TWEAK"
                    Apply-Tweak -tweak $selectedTweak
                    Pause
                }
            } else {
                Write-Status "Lua chon khong hop le!" -Type 'WARNING'
                Pause
            }
        } else {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
