# Copy contents from C:\Users\javilaurin\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 to ./$profile
$profilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path -Path $profilePath) {
    $backupProfilePath = "D:\custom-configs\ps-profile\profile.ps1"
    Copy-Item -Path $profilePath -Destination $backupProfilePath -Force
    Write-Host "Backup created at: $backupProfilePath"
} else {
    Write-Host "Profile file does not exist at: $profilePath"
}
