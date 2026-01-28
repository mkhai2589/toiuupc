# Compile.ps1 - Build bundled one-file for one-liner
$Output = "ToiUuPC-Bundled.ps1"

if (Test-Path $Output) { Remove-Item $Output }

"# PMK Toolbox v3.0 Bundled" | Out-File $Output -Encoding utf8

Get-Content "functions\*.ps1" | Add-Content $Output

Get-Content "ToiUuPC.ps1" | Where-Object { $_ -notmatch '^\.' } | Add-Content $Output  # Skip dot-source

Write-Host "Built: $Output - Use for releases/one-liner."
