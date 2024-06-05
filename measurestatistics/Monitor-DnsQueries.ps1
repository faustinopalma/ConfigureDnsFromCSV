param (  
    # Retrieve the hostname of the machine  
    #[string]$hostname = (Get-ComputerInfo -Property CsName).CsName,  
    [string]$hostname = (Get-WmiObject -Class Win32_ComputerSystem).Name,  #powershell 5 compatible
  
    # Parameter for the path to the CSV file, defaulting to the script's directory with hostname  
    [string]$csvFilePath = "$PSScriptRoot\Output_$hostname.csv",  
  
    # Parameter for the time interval in minutes  
    [int]$intervalMinutes = 5  
) 

# Check if the CSV file exists; if not, create it with headers
if (-not (Test-Path $csvFilePath)) {
    # Add headers to the CSV file
    "Timestamp,TotalQueryReceivedPerSec" | Out-File -FilePath $csvFilePath
}

# Function to get DNS Total Query Received/sec and write to CSV
function Write-DnsQueryStatsToCsv {
    # Get the current timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Retrieve the DNS Total Query Received/sec counter
    $dnsStats = Get-Counter -Counter "\DNS\Total Query Received/sec"
    Write-Output $dnsStats

    # Prepare the data line with timestamp and counter value
    $dataLine = "$timestamp,$($dnsStats.CounterSamples.CookedValue)"

    # Append the data line to the CSV file
    $dataLine | Out-File -FilePath $csvFilePath -Append
}

# Calculate the interval in seconds
$intervalSeconds = $intervalMinutes * 60

# Infinite loop to run the function at the specified interval
while ($true) {
    Write-DnsQueryStatsToCsv
    Start-Sleep -Seconds $intervalSeconds
}