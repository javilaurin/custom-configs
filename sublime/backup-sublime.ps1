# Define source and destination folders (replace with your actual paths)
$sourceFolder = "~\AppData\Roaming\Sublime Text\Packages\User\"
$backupFolder = "$PSScriptRoot\plugin-files\"

# Get all files from the source folder
Get-ChildItem -Path $sourceFolder -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination ($backupFolder + "\" + $_.Name) -Force
}

Write-Host "Finished copying files to backup. Remember to install Package Control manually"
