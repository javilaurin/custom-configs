# Copy contents from C:\Users\javilaurin\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 to ./$profile
$profilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path -Path $profilePath) {
  $backupProfilePath = 'D:\custom-configs\ps-profile\profile.ps1'
  $oldContent = if (Test-Path $backupProfilePath) { Get-Content $backupProfilePath -Raw } else { '' }
  $newContent = Get-Content $profilePath -Raw
  if ($oldContent -ne $newContent) {
    Copy-Item -Path $profilePath -Destination $backupProfilePath -Force
    Write-Host "Backup created at: $backupProfilePath"
    exit 0
  }
} else {
  Write-Host "Profile file does not exist at: $profilePath"
}

exit 11
