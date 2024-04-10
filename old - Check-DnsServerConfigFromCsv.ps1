<#  
.SYNOPSIS  
This PowerShell script checks a DNS server configuration against expected settings from CSV files and outputs a report file.  
  
.DESCRIPTION  
The script uses CSV files to verify global forwarders, conditional forwarders, secondary zones, root hints, delegations, and stub zones on a DNS server.  
  
.EXAMPLE  
C:\PS> .\Check-DnsServerConfigFromCsv.ps1 -RemoteServer 'dns01.example.com'  
  
This example checks the DNS server configuration on 'dns01.example.com' against the provided CSV files and outputs a report.  
  
.PARAMETER RemoteServer  
The DNS server that you want to check.  
  
.NOTES  
Make sure to run this script with administrative privileges on the jump host.  
Each CSV file must be formatted correctly for the script to work.  
PowerShell remoting must be enabled on the remote server.  
#>  
  
param (  
    [Parameter(Mandatory)]  
    [string]$RemoteServer  
)  
  
# Define the path to the CSV files using $PSScriptRoot  
$forwardersCsv = Join-Path $PSScriptRoot 'forwarders.csv'  
$conditionalForwardersCsv = Join-Path $PSScriptRoot 'conditional_forwarders.csv'  
$secondaryZonesCsv = Join-Path $PSScriptRoot 'secondary_zones.csv'  
$rootHintsCsv = Join-Path $PSScriptRoot 'root_hints.csv'  
$delegationsCsv = Join-Path $PSScriptRoot 'delegations.csv'  
$stubZonesCsv = Join-Path $PSScriptRoot 'stub_zones.csv'  
  
# Report file path  
$reportFilePath = Join-Path $PSScriptRoot 'DnsConfigReport.txt'  
  
# Create or clear the report file  
Set-Content -Path $reportFilePath -Value "DNS Configuration Report - $(Get-Date)`n"  
  
# Function to compare objects and append differences to the report  
Function Compare-Objects {  
    Param ($current, $expected, $configType)  
    $differences = Compare-Object -ReferenceObject $current -DifferenceObject $expected  
    If ($differences) {  
        $diffOutput = $differences | Out-String  
        Add-Content -Path $reportFilePath -Value "$configType configuration does not match:`n$diffOutput`n"  
    } Else {  
        Add-Content -Path $reportFilePath -Value "$configType configuration matches.`n"  
    }  
}  
  
# Function to check global forwarders  
Function Check-GlobalForwarders {  
    Param ($session, $expectedForwarders, $reportFilePath)  
    $currentForwarders = Invoke-Command -Session $session -ScriptBlock { Get-DnsServerForwarder | Select-Object -ExpandProperty IPAddress | Sort-Object }  
    $expectedForwardersSorted = $expectedForwarders | Sort-Object  
    Compare-Objects -current $currentForwarders -expected $expectedForwardersSorted -configType "Global Forwarders"  
}  
  
# Function to check conditional forwarders  
Function Check-ConditionalForwarders {  
    Param ($session, $expectedConditionalForwarders, $reportFilePath)  
    # Assumed that Get-DnsServerConditionalForwarder cmdlet and corresponding properties exist  
    $currentConditionalForwarders = Invoke-Command -Session $session -ScriptBlock {  
        Get-DnsServerConditionalForwarder | ForEach-Object {  
            [PSCustomObject]@{  
                DomainName = $_.Name  
                ForwarderIPs = ($_.MasterServers | Sort-Object) -join ";"  
            }  
        }  
    }  
    Compare-Objects -current $currentConditionalForwarders -expected $expectedConditionalForwarders -configType "Conditional Forwarders"  
}  
  
# Function to check secondary zones  
Function Check-SecondaryZones {  
    Param ($session, $expectedSecondaryZones, $reportFilePath)  
    # Assumed that Get-DnsServerZone cmdlet and corresponding properties exist  
    $currentSecondaryZones = Invoke-Command -Session $session -ScriptBlock {  
        Get-DnsServerZone | Where-Object { $_.ZoneType -eq 'Secondary' } | ForEach-Object {  
            [PSCustomObject]@{  
                ZoneName = $_.ZoneName  
                MasterServers = ($_.MasterServers | Sort-Object) -join ";"  
            }  
        }  
    }  
    Compare-Objects -current $currentSecondaryZones -expected $expectedSecondaryZones -configType "Secondary Zones"  
}  
  
# Function to check root hints  
Function Check-RootHints {  
    Param ($session, $expectedRootHints, $reportFilePath)  
    # Assumed that Get-DnsServerRootHint cmdlet and corresponding properties exist  
    $currentRootHints = Invoke-Command -Session $session -ScriptBlock {  
        Get-DnsServerRootHint | ForEach-Object {  
            [PSCustomObject]@{  
                HostName = $_.NameHost  
                IPAddress = $_.IPAddress  
            }  
        } | Sort-Object -Property HostName  
    }  
    $expectedRootHintsSorted = $expectedRootHints | Sort-Object -Property HostName  
    Compare-Objects -current $currentRootHints -expected $expectedRootHintsSorted -configType "Root Hints"  
}  
  
# Function to check delegations  
Function Check-Delegations {  
    Param ($session, $expectedDelegations, $reportFilePath)  
    # Assumed that Get-DnsServerZoneDelegation cmdlet and corresponding properties exist  
    # This is a placeholder; actual implementation will depend on how delegations are retrieved and structured  
    $currentDelegations = Invoke-Command -Session $session -ScriptBlock {  
        # Hypothetical command to get delegations  
        Get-DnsServerZoneDelegation | ForEach-Object {  
            # Hypothetical structure of the delegation object  
            [PSCustomObject]@{  
                ChildZone = $_.ChildZone  
                NameServer = $_.NameServer  
                NameServerIP = $_.NameServerIP  
            }  
        } | Sort-Object -Property ChildZone  
    }  
    $expectedDelegationsSorted = $expectedDelegations | Sort-Object -Property ChildZone  
    Compare-Objects -current $currentDelegations -expected $expectedDelegationsSorted -configType "Delegations"  
}  
  
# Function to check stub zones  
Function Check-StubZones {  
    Param ($session, $expectedStubZones, $reportFilePath)  
    # Assumed that Get-DnsServerStubZone cmdlet and corresponding properties exist  
    $currentStubZones = Invoke-Command -Session $session -ScriptBlock {  
        Get-DnsServerStubZone | ForEach-Object {  
            [PSCustomObject]@{  
                ZoneName = $_.ZoneName  
                MasterServers = ($_.MasterServers | Sort-Object) -join ";"  
            }  
        }  
    }  
    Compare-Objects -current $currentStubZones -expected $expectedStubZones -configType "Stub Zones"  
}  
  
# Create a new PowerShell session on the remote server  
$session = New-PSSession -ComputerName $RemoteServer  
  
# Check global forwarders  
If (Test-Path -Path $forwardersCsv) {  
    $expectedForwarders = Import-Csv -Path $forwardersCsv | Select-Object -ExpandProperty IPAddress  
    Check-GlobalForwarders -session $session -expectedForwarders $expectedForwarders -reportFilePath $reportFilePath  
} Else {  
    Add-Content -Path $reportFilePath -Value "The forwarders CSV file was not found.`n"  
}  
  
# Check conditional forwarders  
If (Test-Path -Path $conditionalForwardersCsv) {  
    $expectedConditionalForwarders = Import-Csv -Path $conditionalForwardersCsv | Select-Object DomainName, ForwarderIPs  
    Check-ConditionalForwarders -session $session -expectedConditionalForwarders $expectedConditionalForwarders -reportFilePath $reportFilePath  
} Else {  
    Add-Content -Path $reportFilePath -Value "The conditional forwarders CSV file was not found.`n"  
}  
  
# Check secondary zones  
If (Test-Path -Path $secondaryZonesCsv) {  
    $expectedSecondaryZones = Import-Csv -Path $secondaryZonesCsv | Select-Object ZoneName, MasterServers  
    Check-SecondaryZones -session $session -expectedSecondaryZones $expectedSecondaryZones -reportFilePath $reportFilePath  
} Else {  
    Add-Content -Path $reportFilePath -Value "The secondary zones CSV file was not found.`n"  
}  
  
# Check root hints  
If (Test-Path -Path $rootHintsCsv) {  
    $expectedRootHints = Import-Csv -Path $rootHintsCsv | Select-Object HostName, IPAddress  
    Check-RootHints -session $session -expectedRootHints $expectedRootHints -reportFilePath $reportFilePath  
} Else {  
    Add-Content -Path $reportFilePath -Value "The root hints CSV file was not found.`n"  
}  
  
# Check delegations  
If (Test-Path -Path $delegationsCsv) {  
    $expectedDelegations = Import-Csv -Path $delegationsCsv | Select-Object ChildZone, NameServer, NameServerIP  
    Check-Delegations -session $session -expectedDelegations $expectedDelegations -reportFilePath $reportFilePath  
} Else {  
    Add-Content -Path $reportFilePath -Value "The delegations CSV file was not found.`n"  
}  
  
# Check stub zones  
If (Test-Path -Path $stubZonesCsv) {  
    $expectedStubZones = Import-Csv -Path $stubZonesCsv | Select-Object ZoneName, MasterServers  
    Check-StubZones -session $session -expectedStubZones $expectedStubZones -reportFilePath $reportFilePath  
} Else {  
    Add-Content -Path $reportFilePath -Value "The stub zones CSV file was not found.`n"  
}  
  
# Close the PowerShell session  
Remove-PSSession -Session $session  
  
Write-Host "DNS server configuration check is complete. Report saved to $reportFilePath."  
