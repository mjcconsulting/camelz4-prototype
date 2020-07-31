Write-Host 'Rename Computer'
Try {
    Rename-Computer -NewName @hostname@

    Write-Host 'Create JoinDomain Script'
    $ScriptPath = 'C:\Windows\Setup\Scripts\CAMELZ-JoinDomain.ps1'
    $Content = @'
$LogDir = 'C:\ProgramData\Amazon\EC2-Windows\Launch\Log'
Start-Transcript -Path "$LogDir\JoinDomainTranscript.log" -NoClobber
Write-Host 'Join Domain'

$Domain = (Get-SSMParameterValue -Name Domain).Parameters[0].Value
Try {
    $User = (Get-SSMParameterValue -Name Domain-Join-User).Parameters[0].Value
    $SecurePassword = (Get-SSMParameterValue -Name Domain-Join-Password -WithDecryption $True).Parameters[0].Value | ConvertTo-SecureString -asPlainText -Force
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
