function Confirm-Action {
    param($Message)
    $r = Read-Host "$Message (y/n)"
    return $r -eq "y"
}
