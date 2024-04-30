# Define the path to the dns-configs folder  
$dnsConfigsPath = Join-Path -Path $PSScriptRoot -ChildPath "dns-configs"  
  
# Get the list of server folders in the dns-configs directory  
$serverFolders = Get-ChildItem -Path $dnsConfigsPath -Directory  
  
# Loop through each server folder  
foreach ($serverFolder in $serverFolders) {  
    # Define the server name from the folder name  
    $serverName = $serverFolder.Name  
  
    # Define the path to the CSV files for the current server  
    $forwardersPath = Join-Path -Path $serverFolder.FullName -ChildPath "forwarders.csv"  
    $conditionalForwardersPath = Join-Path -Path $serverFolder.FullName -ChildPath "conditional_forwarders.csv"  
    $secondaryZonesPath = Join-Path -Path $serverFolder.FullName -ChildPath "secondary_zones.csv"  
    $rootHintsPath = Join-Path -Path $serverFolder.FullName -ChildPath "root_hints.csv"  
    $delegationsPath = Join-Path -Path $serverFolder.FullName -ChildPath "delegations.csv"  
    $stubZonesPath = Join-Path -Path $serverFolder.FullName -ChildPath "stub_zones.csv"  
  
    # Configure forwarders  
    if (Test-Path $forwardersPath) {  
        $forwarders = Import-Csv -Path $forwardersPath  
        foreach ($forwarder in $forwarders) {  
            # Assuming the CSV has a column named 'IPAddress'  
            Add-DnsServerForwarder -ComputerName $serverName -IPAddress $forwarder.IPAddress  
        }  
    }  

    # Configure conditional forwarders  
    if (Test-Path $conditionalForwardersPath) {  
        $conditionalForwarders = Import-Csv -Path $conditionalForwardersPath
        foreach ($conditionalForwarder in $conditionalForwarders) {  
            # Assuming the CSV has columns named 'Name' and 'MasterServers'
            if (Get-DnsServerZone -ComputerName $serverName -Name $conditionalForwarder.Name -ErrorAction SilentlyContinue) {
                Set-DnsServerConditionalForwarderZone -ComputerName $serverName -Name $conditionalForwarder.Name -MasterServers $conditionalForwarder.MasterServers.Split(';')
            } else {
                Add-DnsServerConditionalForwarderZone -ComputerName $serverName -Name $conditionalForwarder.Name -MasterServers $conditionalForwarder.MasterServers.Split(';')
            }
        }  
    }
<#
    # Configure secondary zones  
    if (Test-Path $secondaryZonesPath) {  
        $secondaryZones = Import-Csv -Path $secondaryZonesPath  
        foreach ($secondaryZone in $secondaryZones) {  
            # Assuming the CSV has columns named 'Name' and 'MasterServers'  
            Add-DnsServerSecondaryZone -ComputerName $serverName -Name $secondaryZone.Name -MasterServers $secondaryZone.MasterServers.Split(';')
        }  
    }  

    # Configure root hints  
    if (Test-Path $rootHintsPath) {  
        $rootHints = Import-Csv -Path $rootHintsPath  
        foreach ($rootHint in $rootHints) {  
            # Assuming the CSV has columns named 'NameServer' and 'IPAddress'  
            Set-DnsServerRootHint -ComputerName $serverName -NameServer $rootHint.NameServer -IPAddress $rootHint.IPAddress  
        }  
    }  
  
    # Configure delegations  
    if (Test-Path $delegationsPath) {  
        $delegations = Import-Csv -Path $delegationsPath  
        foreach ($delegation in $delegations) {  
            # Assuming the CSV has columns named 'ChildZoneName', 'NameServer', 'IPAddress', and 'ParentZoneName'  
            Add-DnsServerZoneDelegation -ComputerName $serverName -ChildZoneName $delegation.ChildZoneName -NameServer $delegation.NameServer -IPAddress $delegation.IPAddress -ParentZoneName $delegation.ParentZoneName  
        }  
    }  
  
    # Configure stub zones  
    if (Test-Path $stubZonesPath) {  
        $stubZones = Import-Csv -Path $stubZonesPath  
        foreach ($stubZone in $stubZones) {  
            # Assuming the CSV has columns named 'Name' and 'MasterServers'  
            Add-DnsServerStubZone -ComputerName $serverName -Name $stubZone.Name -MasterServers $stubZone.MasterServers  
        }  
    }
#>
}  
  
# Output completion message  
Write-Host "DNS configurations have been applied to all specified servers."  
