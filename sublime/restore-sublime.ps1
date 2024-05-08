# Define source and destination folders (replace with your actual paths)
$sourceFolder = "$PSScriptRoot\plugin-files\"
$backupFolder = "~\AppData\Roaming\Sublime Text\Packages\User\"

# Get all files from the source folder
Get-ChildItem -Path $sourceFolder -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination ($backupFolder + "\" + $_.Name) -Force
}

Write-Host "Finished restoring files"
