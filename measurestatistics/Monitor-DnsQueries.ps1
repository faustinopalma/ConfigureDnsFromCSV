param (
    # Retrieve the hostname of the machine
    #[string]$hostname = (Get-ComputerInfo -Property CsName).CsName,
    [string]$hostname = (Get-WmiObject -Class Win32_ComputerSystem).Name,  # PowerShell 5 compatible

    # Parameter for the path to the CSV file, defaulting to the script's directory with hostname
    [string]$csvFilePath = "$PSScriptRoot\Output_$hostname.csv",

    # Parameter for the time interval in minutes
    [int]$intervalMinutes = 5,

    # Parameter for the script's lifetime in minutes, defaulting to 8 hours (480 minutes)
    [int]$lifetimeMinutes = 480
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

# Calculate the end time based on the lifetime parameter
$endTime = (Get-Date).AddMinutes($lifetimeMinutes)

# Loop to run the function at the specified interval until the end time is reached
while ((Get-Date) -lt $endTime) {
    Write-DnsQueryStatsToCsv
    Start-Sleep -Seconds $intervalSeconds
}

# Optional: Output a message indicating the script has finished
Write-Output "Script finished at $(Get-Date) after running for $lifetimeMinutes minutes."