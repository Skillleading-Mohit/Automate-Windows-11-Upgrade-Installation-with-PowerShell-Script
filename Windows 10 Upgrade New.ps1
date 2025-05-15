$ComputerName = $env:COMPUTERNAME
$LogPath = "C:\${ComputerName}_Windows11Logs.txt"
$SharedISOPath = "C:\ISO\Win11_23H2_English_x64.iso" # file on share folder which will be copied to the local path
$LocalISOPath = "C:\iso-file\Win11_23H2.iso" #Local file copied from share folder

"===== Windows 11 23H2 Update Script Started: $(Get-Date) =====" | Out-File -FilePath $LogPath -Encoding UTF8
 
Try {
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force
    "Execution policy set to RemoteSigned successfully." | Out-File -FilePath $LogPath -Append
} Catch {
    "Failed to set Execution Policy: $_" | Out-File -FilePath $LogPath -Append
}
 

If (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Try {
        Install-PackageProvider -Name NuGet -Force | Out-Null
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -AllowClobber
        "PSWindowsUpdate module installed successfully." | Out-File -FilePath $LogPath -Append
    } Catch {
        "Failed to install PSWindowsUpdate: $_" | Out-File -FilePath $LogPath -Append
        Exit
    }
} Else {
    "PSWindowsUpdate module already installed." | Out-File -FilePath $LogPath -Append
}
 
Try {
    Import-Module PSWindowsUpdate -Force
    "PSWindowsUpdate module imported successfully." | Out-File -FilePath $LogPath -Append
} Catch {
    "Failed to import PSWindowsUpdate: $_" | Out-File -FilePath $LogPath -Append
    Exit
}
 

Try {
    $AvailableUpdates = Get-WindowsUpdate -MicrosoftUpdate -IgnoreUserInput -AcceptAll -Verbose 4>&1 | Tee-Object -Variable UpdateResult
    $AvailableUpdates | Out-File -FilePath $LogPath -Append
 
    $TargetUpdate = $UpdateResult | Where-Object { $_ -match "Windows 11 Version 23H2" }
 
    If ($TargetUpdate) {
        "Windows 11 23H2 update is available. Installing..." | Out-File -FilePath $LogPath -Append
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose 4>&1 | Out-File -FilePath $LogPath -Append
    } Else {
        "Update not found. Proceeding with ISO installation..." | Out-File -FilePath $LogPath -Append
 
     
        Try {
            If (-Not (Test-Path "C:\iso-file")) {
                New-Item -Path "C:\iso-file" -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $SharedISOPath -Destination $LocalISOPath -Force
            "ISO file copied to local path." | Out-File -FilePath $LogPath -Append
        } Catch {
            "Failed to copy ISO file: $_" | Out-File -FilePath $LogPath -Append
            Exit
        }
 
      
        Try {
            $mount = Mount-DiskImage -ImagePath $LocalISOPath -PassThru
            Start-Sleep -Seconds 5
            $DriveLetter = ($mount | Get-Volume).DriveLetter
            $SetupPath = "$DriveLetter`:\setup.exe"
            "ISO mounted to drive $DriveLetter. Running setup..." | Out-File -FilePath $LogPath -Append
        } Catch {
            "Failed to mount ISO: $_" | Out-File -FilePath $LogPath -Append
            Exit
        }
 
        
        Try {
            Start-Process -FilePath $SetupPath -ArgumentList "/auto upgrade /quiet /noreboot /compat ignorewarning" -Wait
            "Setup launched successfully." | Out-File -FilePath $LogPath -Append
        } Catch {
            "Failed to launch setup: $_" | Out-File -FilePath $LogPath -Append
        }
    }
} Catch {
    "Error while checking or installing update: $_" | Out-File -FilePath $LogPath -Append
}
 
"===== Script Completed (Before Reboot): $(Get-Date) =====" | Out-File -FilePath $LogPath -Append