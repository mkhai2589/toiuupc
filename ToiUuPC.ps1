# =========================================
# ToiUuPC - Controller (WinUtil Style)
# =========================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ---------- ADMIN ----------
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
 [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Run PowerShell as Administrator"
    exit
}

# ---------- PATH ----------
$ROOT = Join-Path $env:TEMP "ToiUuPC"
$FUNC = Join-Path $ROOT "functions"
$CFG  = Join-Path $ROOT "config"
$RUN  = Join-Path $ROOT "runtime"
$BK   = Join-Path $RUN  "backup"

$null = New-Item $FUNC,$CFG,$RUN,$BK -ItemType Directory -Force

# ---------- LOAD FUNCTIONS ----------
Get-ChildItem $FUNC -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}

# ---------- LOAD JSON ----------
$TweaksJson = Get-Content "$CFG\tweaks.json" | ConvertFrom-Json
$AppsJson   = Get-Content "$CFG\applications.json" | ConvertFrom-Json
$DnsJson    = Get-Content "$CFG\dns.json" | ConvertFrom-Json

# ---------- HELPERS ----------
function Select-Multi {
    param($Items)

    $map = @{}
    $i = 1
    foreach ($it in $Items) {
        Write-Host "$i. $($it.name)"
        $map[$i] = $it.id
        $i++
    }

    $raw = Read-Host "Nhap so (vd: 1,3,5)"
    $raw -split "," | ForEach-Object { $map[[int]$_] }
}

# ---------- MENU ----------
function Show-Menu {
    Clear-Host
    Write-Host "=========== TOI UU PC ==========="
    Write-Host "1. Windows tweaks"
    Write-Host "2. Undo tweaks"
    Write-Host "3. Install apps"
    Write-Host "4. DNS"
    Write-Host "5. Clean system"
    Write-Host "0. Exit"
}

# ---------- MAIN ----------
do {
    Show-Menu
    $c = Read-Host "Chon"

    switch ($c) {

        "1" {
            $selected = Select-Multi $TweaksJson
            Invoke-SystemTweaks `
                -Config $TweaksJson `
                -SelectedIds $selected `
                -BackupPath $BK
        }

        "2" {
            Undo-SystemTweaks -BackupPath $BK
        }

        "3" {
            $selected = Select-Multi $AppsJson
            Invoke-AppInstaller `
                -Config $AppsJson `
                -SelectedIds $selected
        }

        "4" {
            Write-Host "1. Google DNS"
            Write-Host "2. Cloudflare DNS"
            Write-Host "3. Reset DNS"
            $d = Read-Host "Chon"

            if ($d -eq "1") { Set-DnsProfile "google" }
            if ($d -eq "2") { Set-DnsProfile "cloudflare" }
            if ($d -eq "3") { Reset-DnsProfile }
        }

        "5" {
            Invoke-CleanSystem -Mode "All"
        }
    }

    if ($c -ne "0") { pause }

} while ($c -ne "0")
