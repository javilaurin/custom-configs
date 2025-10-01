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

$sshPath = "${env:USERPROFILE}\.ssh"
$ssmPath = "${env:USERPROFILE}\.aws"
$ssmCacheFile = Join-Path -Path $ssmPath -ChildPath 'ssm-cache.json'

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

# SSM
# =============================================================================
# AWS SSM Session Manager Helper Functions
# =============================================================================

function Update-SsmCache {
  <#
    .SYNOPSIS
        Queries all AWS regions for instances in ANY state and builds a local cache file.
    #>
  Write-Host -ForegroundColor Cyan '🔎 Starting AWS instance cache update...'

  if (-not (Test-Path $ssmPath)) {
    New-Item -ItemType Directory -Path $ssmPath | Out-Null
  }

  $regions = (aws ec2 describe-regions --query 'Regions[].RegionName' --output text) -split '\s+'

  $instanceData = $regions | ForEach-Object -Parallel {
    $region = $_
        
    # --- CHANGE: Removed the state filter to fetch instances in ALL states ---
    # It still filters for instances that have a 'Name' tag to keep the list relevant.
    $awsCliArgs = @('ec2', 'describe-instances', '--region', $region, '--filters', 'Name=tag-key,Values=Name', '--output', 'json')
        
    $jsonData = (aws @awsCliArgs) | ConvertFrom-Json
        
    if ($null -ne $jsonData.Reservations) {
      foreach ($reservation in $jsonData.Reservations) {
        foreach ($instance in $reservation.Instances) {
          $nameTag = ($instance.Tags | Where-Object { $_.Key -eq 'Name' }).Value
                    
          Write-Output ([PSCustomObject]@{
              InstanceId       = $instance.InstanceId
              Name             = $nameTag.Trim()
              PrivateIpAddress = $instance.PrivateIpAddress
              AvailabilityZone = $instance.Placement.AvailabilityZone
              Region           = $region
              State            = $instance.State.Name
            })
        }
      }
    }
  }

  $instanceData | Sort-Object -Property Name | ConvertTo-Json | Set-Content -Path $ssmCacheFile
    
  Write-Host -ForegroundColor Green "✅ Cache updated successfully with $($instanceData.Count) instances."
}

function ssm {
    <#
    .SYNOPSIS
        Connects to a running EC2 instance using SSM Session Manager via a terminal-based fuzzy finder.
    #>
    param(
        [string]$Pattern
    )

    if (-not (Test-Path $ssmCacheFile)) {
        Write-Host -ForegroundColor Yellow "⏳ Local instance cache not found. Running 'Update-SsmCache' for you..."
        Update-SsmCache

        if (-not (Test-Path $ssmCacheFile)) {
            Write-Host -ForegroundColor Red '❌ Cache update failed. Cannot proceed.'
            return
        }
    }

    $cache = Get-Content -Path $ssmCacheFile | ConvertFrom-Json
    $connectableCache = $cache | Where-Object { $_.State -eq 'running' }
    
    $instanceMatches = $null
    if ([string]::IsNullOrWhiteSpace($Pattern)) {
        $instanceMatches = $connectableCache
    }
    else {
        $instanceMatches = $connectableCache | Where-Object { $_.Name -like "*$Pattern*" }
    }

    $targetInstance = $null

    if ($instanceMatches.Count -eq 0) {
        $errorMessage = if ([string]::IsNullOrWhiteSpace($Pattern)) {
            "❌ No *running* instances found in the cache. Run 'Update-SsmCache'."
        } else {
            "❌ No matching *running* instances found in the cache for pattern '$Pattern'."
        }
        Write-Host -ForegroundColor Red $errorMessage
        return
    }
    elseif ($instanceMatches.Count -eq 1) {
        $targetInstance = $instanceMatches
        Write-Host -ForegroundColor Green "✅ Found unique instance: $($targetInstance.Name)"
    }
    else {
        Write-Host -ForegroundColor Yellow "Multiple running instances found. Please choose one using the fuzzy finder:"
        
        # --- FIX: Added the InstanceId back to the formatted string for fzf ---
        $selection = $instanceMatches | ForEach-Object { "{0,-40} {1,-15} {2,-15} {3,-10} {4}" -f $_.Name, $_.PrivateIpAddress, $_.Region, $_.State, $_.InstanceId } | fzf
        
        if ([string]::IsNullOrWhiteSpace($selection)) {
            Write-Host -ForegroundColor Red "❌ Selection cancelled."
            return
        }
        
        # This logic now works correctly because the InstanceId is the last element
        $selectedId = ($selection.Trim() -split '\s+')[-1]
        
        $targetInstance = $instanceMatches | Where-Object { $_.InstanceId -eq $selectedId }
    }

    if ($null -ne $targetInstance) {
        Write-Host "🚀 Connecting to $($targetInstance.Name) ($($targetInstance.InstanceId))..."
        aws ssm start-session --target $targetInstance.InstanceId --region $targetInstance.Region
    }
}

# Argument completion
# =============================================================================
# Argument Completer for the custom 'ssm' function
# =============================================================================
# This makes Tab-completion work for `ssm <partial-name>`

Register-ArgumentCompleter -CommandName 'ssm' -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)

  # Define the path to the cache file, just like in the other functions
  $ssmCacheFile = Join-Path -Path $HOME -ChildPath '.aws/ssm-cache.json'

  # If the cache file doesn't exist, we can't offer any suggestions.
  if (-not (Test-Path $ssmCacheFile)) {
    # You could optionally return a suggestion to run the update command:
    # return "'Cache is empty. Run Update-SsmCache'"
    return 
  }

  # Read the JSON cache, get the list of instance names, and sort them
  $instanceNames = Get-Content -Path $ssmCacheFile | ConvertFrom-Json | Select-Object -ExpandProperty Name | Sort-Object -Unique

  # Find all names that contain the text the user has started typing
  # The '*' wildcards mean it will match anywhere in the name, not just the start.
  $instanceNames | Where-Object { $_ -like "*${wordToComplete}*" } | ForEach-Object {
    # For names with spaces, PowerShell needs them to be quoted to be completed correctly.
    if ($_ -match '\s') {
      "'$_'"
    }
    else {
      $_
    }
  }
}


#######################################################
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
