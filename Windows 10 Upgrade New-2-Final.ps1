
$ComputerName = $env:COMPUTERNAME
$LogPath = "\\rbi-d-349\ScanEDD\VI\${ComputerName}_Win11InstallationLogs.txt"
$TrLogPath = "\\rbi-d-349\ScanEDD\VI\${ComputerName}_Transcript_Logs.txt"
$SharedISOPath = "\\rbi-d-349\License Software\windows\Win11_24H2_English_x64.iso"
$LocalISOPath = "C:\iso-file\Win11_24H2.iso"

Start-Transcript -Path $TrLogPath -Append #for terminal logs
Write-Verbose "===== Starting Windows 11 24H2 Update Script =====" -Verbose # for custom logs "Elements Based"
"===== Script Start: $(Get-Date) =====" | Out-File -FilePath $LogPath -Encoding UTF8

Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("Hello!! Windows 11 upradation has been started on your system and it would take 2-3 hours so please save your work and don't let the system to be switched off, For any help, please may contact Local IT person ", "MAT India IT Team", "OK", "Information")

Try {
    Write-Verbose "Setting execution policy..." -Verbose
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force
    "Execution policy set to RemoteSigned." | Out-File -FilePath $LogPath -Append
} Catch {
    Write-Verbose "Execution policy failed: $_" -Verbose
    "Execution policy failed: $_" | Out-File -FilePath $LogPath -Append
}

        if (-not (Test-Path "C:\iso-file")) {
            New-Item -Path "C:\iso-file" -ItemType Directory -Force | Out-Null
            Write-Verbose "Created C:\iso-file folder." -Verbose
        }
 
        Try {
            Write-Verbose "Copying ISO from shared folder..." -Verbose
            Copy-Item -Path $SharedISOPath -Destination $LocalISOPath -Force -Verbose
            "ISO copied to $LocalISOPath" | Out-File -FilePath $LogPath -Append
        } Catch {
            Write-Verbose "ISO copy failed: $_" -Verbose
            "ISO copy failed: $_" | Out-File -FilePath $LogPath -Append
            Exit
        }


       
        Try {
            Write-Verbose "Mounting ISO..." -Verbose
            $mount = Mount-DiskImage -ImagePath $LocalISOPath -PassThru -Verbose
            Start-Sleep -Seconds 5
            $volume = Get-Volume -DiskImage $mount
            $DriveLetter = $volume.DriveLetter
            $SetupPath = "$DriveLetter`:\setup.exe"
            "ISO mounted to $DriveLetter" | Out-File -FilePath $LogPath -Append
        } Catch {
            Write-Verbose "Failed to mount ISO: $_" -Verbose
            "ISO mount failed: $_" | Out-File -FilePath $LogPath -Append
            Exit
        }
 
        # Run setup.exe

        Try {
            Write-Verbose "Launching Windows setup..." -Verbose
            
            Start-Process -FilePath $SetupPath `
            -ArgumentList "/auto upgrade /noreboot /eula accept /dynamicupdate disable" `
            -Wait -Verb RunAs

            "Setup.exe launched successfully." | Out-File -FilePath $LogPath -Append
        }        
        Catch {
            Write-Verbose "Setup.exe failed: $_" -Verbose
            "Setup.exe failed: $_" | Out-File -FilePath $LogPath -Append
        }


 
"===== Script Completed: $(Get-Date) =====" | Out-File -FilePath $LogPath -Append
Write-Verbose "===== Script Completed =====" -Verbose

Stop-Transcript
Write-Output "Script completed. Please reboot manually to continue upgrade." | Tee-Object -FilePath $TrLogPath -Append