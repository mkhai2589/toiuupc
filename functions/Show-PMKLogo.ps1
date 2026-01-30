function Show-PMKLogo {

    [Console]::OutputEncoding = [System.Text.Encoding]::ASCII

    $logo = @(

    
        "PPPPPP  MM    MM  KK   KK   TTTTTT   OOOOO   OOOOO   LL",
        "PP   PP MMM  MMM  KK  KK      TT    OO   OO OO   OO  LL",
        "PPPPPP  MM MM MM  KKKKK       TT    OO   OO OO   OO  LL",
        "PP      MM    MM  KK  KK      TT    OO   OO OO   OO  LL",
        "PP      MM    MM  KK   KK     TT     OOOOO   OOOOO   LLLLL",
        "",

        
        "PMK TOOLBOX - TOI UU WINDOWS",
        "Author : MINH KHAI - 0333090930"


        
    )

    foreach ($l in $logo) {
        Write-Host $l -ForegroundColor Cyan
    }
}
