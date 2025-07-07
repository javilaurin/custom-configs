# Define source and destination folders (replace with your actual paths)
$sourceFolder = '~\AppData\Roaming\Sublime Text\Packages\User\'
$backupFolder = "$PSScriptRoot\plugin-files\"

# Get all files from the source folder
$filesChanged = $false
Get-ChildItem -Path $sourceFolder -File | ForEach-Object {
  $destFile = $backupFolder + '\' + $_.Name
  $srcContent = Get-Content $_.FullName -Raw
  $destContent = if (Test-Path $destFile) { Get-Content $destFile -Raw } else { '' }
  if ($srcContent -ne $destContent) {
    Copy-Item -Path $_.FullName -Destination $destFile -Force
    $filesChanged = $true
  }
}

if ($filesChanged) {
  Write-Host 'Sublime files copied to backup'
  exit 0
}

exit 11
