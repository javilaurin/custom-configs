# Run all backup scripts in the current repository, parenta folder and/or child folders except the one that is currently running
$scriptPath = $PSScriptRoot
$parentPath = Split-Path -Path $scriptPath -Parent
$childPaths = Get-ChildItem -Path $scriptPath -Directory -Recurse | Select-Object -ExpandProperty FullName
$allPaths = @($scriptPath, $parentPath) + $childPaths
$backupScripts = Get-ChildItem -Path $allPaths -Filter 'backup-*.ps1' -File
$runningScript = $MyInvocation.MyCommand.Name
foreach ($script in $backupScripts) {
    if ($script.Name -ne $runningScript) {
        Write-Host "Running backup script: $($script.FullName)"
        try {
            . $script.FullName
        } catch {
            Write-Error "Failed to run script: $($script.FullName). Error: $_"
        }
    } else {
        Write-Host "Skipping running script: $($script.FullName)"
    }
}