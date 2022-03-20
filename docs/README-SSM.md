# Notes on use of Systems Manager

This is going to start out as a place to just collect stuff I've learned while attempting to use this service and hitting a lot of issues

## Notes in unsorted order
- The log file to trace SSM activity is: C:\ProgramData\Amazon\SSM\Logs\amazon-ssm-agent.log
- You can watch activity in this log by opening a PowerShell Window, expanding the width, the typing:
  ```
  Get-Content -Tail 100 -Wait C:\ProgramData\Amazon\SSM\Logs\amazon-ssm-agent.log
  ```
  If the screen seems to freeze, you may have to hit escape to get it moving again.
- When using aws:application, the application MSI file is downloaded to directory C:\Windows\TEMP\Amazon\SSM\Download,
  with a filename like b13727d63632a9cbe91835631832b82ee357cfcb, which must be some hash of the contents. You can look for the right file if multiple are there by comparing file sizes.
- When a script is run via runPowerShellScript, the script is downloaded to directory C:\ProgramData\Amazon\SSM\InstanceData\<_instance_>\document\orchestration\<_command-id_>\runPowerShellScript
  with the filename \_script.ps1. To monitor repeated attempts, if you sort the orchestration parent directory by modification time, you can quickly get to the latest version of the script that is downloaded before it is run. 
