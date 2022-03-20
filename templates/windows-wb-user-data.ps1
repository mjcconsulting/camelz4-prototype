<powershell>
$LogDir = 'C:\ProgramData\Amazon\EC2-Windows\Launch\Log'
Start-Transcript -Path "$LogDir\UserdataTranscript.log" -NoClobber


Write-Host 'Set Administrator Password'
$Password = (Get-SSMParameterValue -Name @administrator_password_parameter@ -WithDecryption $True).Parameters[0].Value | ConvertTo-SecureString -asPlainText -Force
Set-LocalUser -Name Administrator -Password $Password


Write-Host 'Enable Ping'
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow


Write-Host 'Disable Network Dialog'
New-Item -Path 'HKLM:\System\CurrentControlSet\Control\Network\NewNetworkWindowOff' -Force | Out-Null


Write-Host 'Configure User Profiles'
Try {
    $Profiles=@()

    $AdministratorProfile = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | `
    Where {$_.PSChildName -match 'S-1-5-21-(\d+-?){4}-500$'} | `
    Select-Object @{Name='SID'; Expression={$_.PSChildName}}, @{Name='UserHive';Expression={"$($_.ProfileImagePath)\NTuser.dat"}}
    $Profiles += $AdministratorProfile

    $DefaultProfile = '' | Select-Object SID, UserHive
    $DefaultProfile.SID = 'Default'
    $DefaultProfile.Userhive = 'C:\Users\Default\NTuser.dat'
    $Profiles += $DefaultProfile

    Foreach ($Profile in $Profiles) {
        $User = ($Profile.Userhive -Split '\\')[2]
        Write-Host "- Configure $User"

        If (($Loaded = Test-Path -Path "Registry::HKEY_USERS\$($Profile.SID)") -eq $False) {
            Write-Host "  - Load $User Profile"
            Start-Process -FilePath "CMD.EXE" -ArgumentList "/C REG.EXE LOAD HKU\$($Profile.SID) $($Profile.UserHive)" -Wait -WindowStyle Hidden
        }

        Write-Host '  - Enable Show Hidden Files'
        $Path = "Registry::HKEY_USERS\$($Profile.SID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        If (!(Test-Path -Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name 'Hidden' -Value 1 -Force | Out-Null

        Write-Host '  - Configure Console'
        $Path = "Registry::HKEY_USERS\$($Profile.SID)\Console"
        Set-ItemProperty -Path $Path -Name WindowSize -Value $(160 + (32 -shl 16)) -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ScreenBufferSize -Value $(160 + (5000 -shl 16)) -Force | Out-Null

        Set-ItemProperty -Path $Path -Name FaceName   -Value 'Lucida Console' -Force | Out-Null
        Set-ItemProperty -Path $Path -Name FontFamily -Value 0x00000036 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name FontWeight -Value 0x00000190 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name FontSize   -Value $(14 -shl 16) -Force | Out-Null

        Set-ItemProperty -Path $Path -Name ColorTable00 -Value 0x001e1414 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable01 -Value 0x00642800 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable02 -Value 0x00144632 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable03 -Value 0x00aa9600 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable04 -Value 0x00100880 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable05 -Value 0x00400820 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable06 -Value 0x0000aaff -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable07 -Value 0x00e6dcd2 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable08 -Value 0x00beb4a0 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable09 -Value 0x00f08c28 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable10 -Value 0x0028c882 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable11 -Value 0x00dcc850 -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable12 -Value 0x004040ff -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable13 -Value 0x00d28caa -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable14 -Value 0x0014d2ff -Force | Out-Null
        Set-ItemProperty -Path $Path -Name ColorTable15 -Value 0x00f0faff -Force | Out-Null

        Set-ItemProperty -Path $Path -Name ScreenColors -Value 0x0000005F -Force | Out-Null
        Set-ItemProperty -Path $Path -Name PopupColors  -Value 0x000000F3 -Force | Out-Null

        $Path = "Registry::HKEY_USERS\$($Profile.SID)\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe"
        If (Test-Path -Path $Path) {
            Remove-Item -Path $Path -Force | Out-Null
        }

        $TargetPath = '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe'
        $ShortcutPath = "C:\Users\$User\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk"

        Remove-Item -Path $ShortcutPath -ErrorAction SilentlyContinue

        $Shell = New-Object -comObject WScript.Shell
        $Shortcut = $Shell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $TargetPath
        $Shortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
        $Shortcut.Description = 'CAMELZ PowerShell'
        $Shortcut.IconLocation = "$TargetPath,0"
        $Shortcut.Save()

        Write-Host '  - Clean up Desktop'
        Remove-Item -Path "C:\Users\$User\Desktop\EC2*" -ErrorAction SilentlyContinue

        If (($Loaded -eq $False) -or ($User -eq 'Default')) {
            Write-Host "  - Unload $User Profile"
            [gc]::Collect()
            Start-Sleep 1
            Start-Process -FilePath "CMD.EXE" -ArgumentList "/C REG.EXE UNLOAD HKU\$($Profile.SID)" -Wait -WindowStyle Hidden| Out-Null
        }
    }
} Catch {
    $Message = 'Exception on line {0}: {1}' -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message
    Write-Error $Message
}


Write-Host 'Configure PowerShell Profile'
@'
$Host.PrivateData.ErrorForegroundColor = 'Red'
$Host.PrivateData.ErrorBackgroundColor = $Host.UI.RawUI.BackgroundColor
$Host.PrivateData.WarningForegroundColor = 'DarkYellow'
$Host.PrivateData.WarningBackgroundColor = $Host.UI.RawUI.BackgroundColor
$Host.PrivateData.DebugForegroundColor = 'Cyan'
$Host.PrivateData.DebugBackgroundColor = $Host.UI.RawUI.BackgroundColor
$Host.PrivateData.VerboseForegroundColor = 'Green'
$Host.PrivateData.VerboseBackgroundColor = $Host.UI.RawUI.BackgroundColor
'@ | Out-File -FilePath C:\Windows\System32\WindowsPowerShell\v1.0\Profile.ps1


Write-Host 'Download Google Chrome Installer'
$Desktop = "$Env:USERPROFILE\Desktop"
$Url = 'http://installers-dxcapm.s3-website-us-east-1.amazonaws.com/GoogleChromeStandaloneEnterprise64.msi'
Try {
    $Delay = 5
    $Counter = 60
    Do {
        Try {
            $Response = Invoke-WebRequest -Uri $Url -Method Head
            $Installer = $Response.BaseResponse.ResponseUri.LocalPath.TrimStart('/')
            Write-Host "- Downloading $Url to $Desktop\$Installer"
            (New-Object System.Net.WebClient).DownloadFile($Url, "$Desktop\$Installer")
            $StatusCode = $Response.StatusCode
        }
        Catch {
            $StatusCode = $_.Exception.Response.StatusCode.value__
            $Message = $_.Exception.Message
            Switch ($Message) {
                'Unable to connect to the remote server' { Write-Host -NoNewline "- $Message." }
                Default { Throw }
            }
            If (--$Counter -gt 0) {
                Write-Host " Trying again in $Delay seconds..."
                Start-Sleep $Delay
            }
            Else {
                Write-Host
                Throw New-Object -TypeName System.TimeoutException('Download attempts exceeded', $_.Exception)
            }
        }
    } Until ($StatusCode -eq 200)
    Write-Host '- Download Succeeded'

    Write-Host 'Install Google Chrome'
    $P = Start-Process -FilePath msiexec.exe -ArgumentList "/I $Desktop\$Installer /QN /L*V ""$LogDir\$($Installer.TrimEnd('.msi')).log""" -NoNewWindow -Wait -PassThru
    If ($P.ExitCode -eq 0) {
        Write-Host '- Install Succeeded'
        Remove-Item "$Desktop\$Installer" -ErrorAction SilentlyContinue
    } Else {
        Write-Error "- Install Failed ($P.ExitCode)"
    }
} Catch {
    $Message = 'Exception on line {0}: {1}' -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message
    Write-Error $Message
}


Write-Host 'Create Adjusted Taskbar Layout'
$FilePath = 'C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\StartLayout.xml'
$Content = @'
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout">
        <start:Group Name="Windows Server" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout">
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Server Manager.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell ISE.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="2" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Administrative Tools.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="2" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\System Tools\Task Manager.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="2" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Control Panel.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="4" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Accessories\Remote Desktop Connection.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="4" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Administrative Tools\Event Viewer.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="4" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
        </start:Group>
        <start:Group Name="" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout">
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Royal TS V5\Royal TS V5.lnk" />
        </start:Group>
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
        <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
        <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk" />
        <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Server Manager.lnk" />
        <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" />
        <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Royal TS V5\Royal TS V5.lnk" />
        <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Accessories\Remote Desktop Connection.lnk" />
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
'@
$Content.Replace("`n","`r`n") | Set-Content -Path $FilePath -Force

Try {
    Write-Host 'Adjust Taskbar Layout'
    $LayoutPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    If (!(Test-Path -Path $LayoutPath)) {
        New-Item -Path $LayoutPath -Force | Out-Null
    }
    New-ItemProperty -Path $LayoutPath -Name StartLayoutFile -Value 'C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\StartLayout.xml' -PropertyType ExpandString -Force | Out-Null
    New-ItemProperty -Path $LayoutPath -Name LockedStartLayout -Value 0 -PropertyType DWord -Force | Out-Null
} Catch {
    $Message = 'Exception on line {0}: {1}' -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message
    Write-Error $Message
}


Write-Host 'Rename Computer'
Try {
    Rename-Computer -NewName @hostname@

    If ('@directory_domain_parameter@' -ne '') {
        Write-Host 'Create JoinDomain Script'
        $ScriptPath = 'C:\Windows\Setup\Scripts\CAMELZ-JoinDomain.ps1'
        $Content = @'
$LogDir = 'C:\ProgramData\Amazon\EC2-Windows\Launch\Log'
Start-Transcript -Path "$LogDir\JoinDomainTranscript.log" -NoClobber
Write-Host 'Join Domain'

$Domain = (Get-SSMParameterValue -Name @directory_domain_parameter@).Parameters[0].Value
Try {
    $User = (Get-SSMParameterValue -Name @directory_domainjoin_user_parameter@).Parameters[0].Value
    $SecurePassword = (Get-SSMParameterValue -Name @directory_domainjoin_password_parameter@ -WithDecryption $True).Parameters[0].Value | ConvertTo-SecureString -asPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($User, $SecurePassword)

    Add-Computer -DomainName $Domain -Credential $Credential -ErrorAction Stop
    Write-Host "Computer $env:ComputerName joined to Domain $Domain"

    Unregister-ScheduledTask -TaskName JoinDomain -Confirm:$False | Out-Null
} Catch {
    $Message = 'Exception on line {0}: {1}' -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message
    Write-Error $Message
} Finally {
    Write-Host 'Restart'
    Restart-Computer
}
'@
        $Content.Replace("`n","`r`n") | Set-Content -Path $ScriptPath -Force

        Write-Host 'Register JoinDomain Startup Task'
        $Action = New-ScheduledTaskAction -Execute 'C:\Windows\System32\cmd.exe' -Argument "/C C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Unrestricted -File `"$ScriptPath`""
        $Trigger = New-ScheduledTaskTrigger -AtStartup
        $Principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        $Settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel
        Register-ScheduledTask -TaskName JoinDomain -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal | Out-Null
    }
} Catch {
    $Message = 'Exception on line {0}: {1}' -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message
    Write-Error $Message
} Finally {
    Write-Host 'Restart'
    Restart-Computer
}
</powershell>
