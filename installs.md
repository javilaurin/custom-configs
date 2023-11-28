# OhMyPosh
www.ohmyposh.dev

# Terminal Icons
PS admin -> Install-Module -Name Terminal-Icons -Repository PSGallery
$PROFILE -> Import-Module -Name Terminal-Icons

# PSReadLine
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows