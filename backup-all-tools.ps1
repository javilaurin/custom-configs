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
    }
    catch {
      Write-Error "Failed to run script: $($script.FullName). Error: $_"
    }
  }
  else {
    Write-Host "Skipping running script: $($script.FullName)"
  }
}

# Current root folder is a git repository, check if this same script made any changes that are not currently commited to the repository, then add, commit and push the changes
if (Test-Path -Path "$scriptPath\.git") {
  Write-Host "Current folder is a git repository: $scriptPath"
  $gitStatus = git -C $scriptPath status --porcelain
  if ($gitStatus) {
    Write-Host 'Changes detected in the custom configs git repository'
    # Ask user for confirmation to add, commit and push changes
    $confirmation = Read-Host "Do you want to add, commit and push these changes? (y/n)"
    if ($confirmation -eq 'y') {
      Write-Host 'Adding, committing and pushing changes...'
      git -C $scriptPath add .
      git -C $scriptPath commit -m "backup - Backup changes made by $runningScript on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      git -C $scriptPath push
      # Write last commit hash and date (as timestamp) to 'lastcommit' file
      Write-Output (git -C $scriptPath log -1 --format="%ct|%H") > lastcommit
    }
  }
  else {
    Write-Host 'No changes detected in the git repository.'
  }
}
else {
  Write-Host "Current folder is not a git repository: $scriptPath"
}
