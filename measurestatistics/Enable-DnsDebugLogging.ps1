# Define the list of DNS servers
# $dnsServers = @("dc01", "DNSServer2", "DNSServer3") # Replace with your DNS server names
$dnsServers = @("dc01")

# Define the log file path and name
$logFilePath = "C:\DNS\DnsDebugLog.log"

# Function to enable DNS debug logging on a server
function Enable-DnsDebugLogging {
    param (
        [string]$Server
    )

    Write-Host "Enabling DNS debug logging on $Server..."

    Invoke-Command -ComputerName $Server -ScriptBlock {
        param ($logFilePath)

        # Load the DNS server module
        Import-Module DNSServer

        # Define the debug logging options
        $debugOptions = @{
            "LogFilePath" = $logFilePath
            "LogIPFilter" = $true
            "LogPacketFilter" = $true
            "LogQueryFilter" = $true
            "LogResponseFilter" = $true
            "LogNonQueryPackets" = $false
        }

        # Enable debug logging
        Set-DnsServerDiagnostics -ComputerName $env:COMPUTERNAME -DebugLogging $true @debugOptions

        # Confirm the settings
        Get-DnsServerDiagnostics -ComputerName $env:COMPUTERNAME
    } -ArgumentList $logFilePath -ErrorAction Stop
}

# Loop through each DNS server and enable debug logging
foreach ($server in $dnsServers) {
    try {
        Enable-DnsDebugLogging -Server $server
        Write-Host "Debug logging enabled on $server successfully."
    }
    catch {
        Write-Host "Failed to enable debug logging on $server : $_"
    }
}
