<powershell>
Start-Transcript -Path "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\UserdataTranscript.txt" -NoClobber

Write-Host "Rename Computer"
Rename-Computer -NewName @hostname@

Write-Host "Set Administrator Password"
NET USER Administrator "@administrator_password@"

Write-Host "Install Chrome"
Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile C:\Users\Administrator\Desktop\chrome_installer.exe
If (\$lastExitCode -eq "0") {
  C:\Users\Administrator\Desktop\chrome_installer.exe /silent /install
}

Write-Host "Clean up Desktop"
Remove-Item "C:\Users\Default\Desktop\EC2 Feedback.website"
Remove-Item "C:\Users\Default\Desktop\EC2 Microsoft Windows Guide.website"

Write-Host "Restart to pick up Hostname change"
Restart-Computer
</powershell>
