<#  
.Synopsis  
   Check the DNS resolution of a list of hostnames.  
.DESCRIPTION  
   This script reads a CSV file containing a list of hostnames and attempts to resolve each one using the DNS server.  
   It outputs the result and a description for each hostname that can be consumed by a Nagios monitoring server.  
  
   Pre-requisites:  
    * Input CSV file with a column named 'HostName'.  
    * Proper permissions to query the DNS server.  
  
   Usage with NSClient++  
   ---------------------  
   Configure the script in NSClient++ for execution and create a Nagios service check as needed.  
  
.NOTES  
   Created by: [Your Name]  
   Modified: [Date]  
  
   Version 1.0  
#>  
  
#Requires -Version 2.0  
Param(  
    # Path to the input CSV file  
    [Parameter(Mandatory=$true)]  
    [string]$InputCsvPath  
)  
  
# Define return states for Nagios  
$returnStateOK = 0  
$returnStateWarning = 1  
$returnStateCritical = 2  
$returnStateUnknown = 3  
  
# Read the hostnames from the CSV file  
try {  
    $hostnames = Import-Csv -Path $InputCsvPath  
}  
catch {  
    Write-Output "Unable to read CSV file from $InputCsvPath." ; exit $returnStateUnknown  
}  
  
# Resolve each hostname and output the result  
foreach ($hostname in $hostnames) {  
    $host = $hostname.HostName  
    try {  
        $ipAddresses = [System.Net.Dns]::GetHostAddresses($host)  
        if ($ipAddresses.Length -gt 0) {  
            $resolvedIPs = ($ipAddresses | Select-Object -ExpandProperty IPAddressToString) -join ', '  
            Write-Output "Resolved $host to IP(s): $resolvedIPs"  
            $result = $returnStateOK  
        }  
        else {  
            Write-Output "Host $host could not be resolved."  
            $result = $returnStateWarning  
        }  
    }  
    catch {  
        Write-Output "Failed to resolve host $host. Error: $_"  
        $result = $returnStateCritical  
    }  
  
    # Output the result for Nagios  
    $description = "DNS Resolution Check for $host"  
    Write-Output "$description|$result"  
}  
  
# Exit with an OK state if the script completes  
exit $returnStateOK  
