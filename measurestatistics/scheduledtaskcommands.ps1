$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-File "C:\Path\To\YourScript.ps1"'  
$trigger = New-ScheduledTaskTrigger -Once -At "2023-10-10T08:00:00"  # Set your desired date and time here  
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest  
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden -StartWhenAvailable  
  
Register-ScheduledTask -TaskName "MyPowerShellScript" -Action $action -Trigger $trigger -Principal $principal -Settings $settings  