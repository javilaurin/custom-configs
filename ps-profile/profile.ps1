# OhMyPosh
# oh-my-posh init pwsh --config 'D:\custom-configs\M365Princess-custom.omp.json' | Invoke-Expression #LOCAL
oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/javilaurin/custom-configs/master/M365Princess-custom.omp.json' | Invoke-Expression # REMOTE

# oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin.omp.json' | Invoke-Expression
# oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/M365Princess.omp.json' | Invoke-Expression
# oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/agnoster.omp.json' | Invoke-Expression
# oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/agnosterplus.omp.json' | Invoke-Expression
# oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/bubbles.omp.json' | Invoke-Expression
# oh-my-posh init pwsh --config '' | Invoke-Expression

Enable-PoshTransientPrompt

# Terminal icons
Import-Module -Name Terminal-Icons

# PSReadLine for autocomplete
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

Set-Alias -Name grep -Value Select-String

# Set $DEVHOME env variable pointing to the current user base git repositories folder
if (-not $env:DEVHOME) {
  if (Test-Path -Path 'D:\okt-api') {
    $env:DEVHOME = 'D:\'
  }
  elseif (Test-Path -Path 'C:\Users\javilaurin\Proyectos') {
    $env:DEVHOME = 'C:\Users\javilaurin\Proyectos'
  }
  else {
    Write-Warning 'DEVHOME environment variable not set. Please set it to your development home directory.'
  }
}

# Check if DEVHOME is set and perform backups
if ($env:DEVHOME) {
  Write-Host "DEVHOME is set to: $($env:DEVHOME)"
  if (Test-Path -Path "$env:DEVHOME\custom-configs") {
    # Write-Host 'Performing custom-configs backup';
    . "$env:DEVHOME\custom-configs\backup-all-tools.ps1"
  }
}
else {
  Write-Warning 'DEVHOME environment variable is not set. Please set it to your development home directory.'
}

# Autocomplete hostnames
function Get-SSHHost($sshConfigPath) {
  Get-Content -Path $sshConfigPath `
  | Select-String -Pattern '^Host ' `
  | ForEach-Object { $_ -replace 'Host ', '' } `
  | ForEach-Object { $_ -split ' ' } `
  | Sort-Object -Unique `
  | Select-String -Pattern '^.*[*!?].*$' -NotMatch
}

$sshPath = "${env:USERPROFILE}\.ssh"

# Argument completion
Register-ArgumentCompleter -CommandName 'ssh', 'scp', 'sftp' -Native -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)

  $hosts = Get-Content -Path "${sshPath}\config" `
  | Select-String -Pattern '^Include ' `
  | ForEach-Object { $_ -replace 'Include ', '' } `
  | ForEach-Object { Get-SSHHost "${sshPath}/$_" }

  $hosts += Get-SSHHost "${sshPath}\config"
  $hosts = $hosts | Sort-Object -Unique

  $hosts | Where-Object { $_ -like "${wordToComplete}*" } | ForEach-Object { $_ }
}

# failed trials and bits

# Register-EngineEvent PowerShell.OnIdle -Action {
#   $cwd = Get-Location
#   if (Test-Path "$cwd\scripts\Set-Env.ps1" -and $Global:LastEnvPath -ne $cwd) {
#     . "$cwd\scripts\Set-Env.ps1"
#     $Global:LastEnvPath = $cwd
#   }
# } | Out-Null

# # Define aliases for ftp servers
# $ftpConfig = Get-Content "${sshPath}\ftp_config.txt"
# foreach ($server in $ftpConfig) {
#   Write-Warning $server
#   $serverInfo = $server -split ' '
#   Write-Warning $serverInfo[1]

#   # Check if we have enough information (4 elements)
#   if ($serverInfo.Length -eq 4) {
#     $name = $serverInfo[0]
#     $hostName = $serverInfo[1].Split('=')[1]
#     $userName = $serverInfo[2].Split('=')[1]
#     $password = $serverInfo[3].Split('=')[1]

#     $aliasName = "ftp_${name}"
#     $aliasCommand = "Invoke-WebRequest -Uri ftp://${hostName}/${userName}:$(${password})@/$ -Method GET"

#     Set-Alias -Name $aliasName -Value $aliasCommand
#   } else {
#     Write-Warning "Invalid server line format in ftp_config.txt: $server"
#   }
# }

# SSH wrapper
# function ssh {
#     param([string]$sshHost)
    
#     $env:SSH_HOST_FOR_TITLE = $sshHost
#     $Host.UI.RawUI.WindowTitle = "SSH: $sshHost"
    
#     & ssh.exe $sshHost
    
#     Remove-Item Env:\SSH_HOST_FOR_TITLE
#     $Host.UI.RawUI.WindowTitle = "PowerShell - $PWD"
# }
