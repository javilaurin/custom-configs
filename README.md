# custom-configs
My own custom configs 

## OhMyPosh!
www.ohmyposh.dev

## PowerShell
### Terminal Icons
- PS admin -> `Install-Module -Name Terminal-Icons -Repository PSGallery`
- $PROFILE -> `Import-Module -Name Terminal-Icons`

### PSReadLine
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

## Sublime

## Backups
- `backup-all-tools.ps1` -> Backs up all other configs in this repository
- `ps-profile/backup-profile.ps1` -> Backs up $PROFILE file
- `sublime\backup-sublime.ps1` -> Backs up sublime text 3 config and plugin files
- `sublime\restore-sublime.ps1` -> Restores sublime text 3 config and plugin files