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
        $currentForwarders = (Get-DnsServerForwarder -ComputerName $serverName).IPAddress | Sort-Object  
        $desiredForwarders = $forwarders.IPAddress | Sort-Object  
  
        if (Compare-Object -ReferenceObject $currentForwarders -DifferenceObject $desiredForwarders) {  
            Set-DnsServerForwarder -ComputerName $serverName -IPAddress $desiredForwarders  
        }  
    }  
  
    # Configure conditional forwarders  
    if (Test-Path $conditionalForwardersPath) {  
        $conditionalForwarders = Import-Csv -Path $conditionalForwardersPath  
        foreach ($conditionalForwarder in $conditionalForwarders) {  
            $currentConditionalForwarder = Get-DnsServerConditionalForwarderZone -ComputerName $serverName -Name $conditionalForwarder.Name -ErrorAction SilentlyContinue  
            if ($null -eq $currentConditionalForwarder -or Compare-Object -ReferenceObject $currentConditionalForwarder.MasterServers -DifferenceObject $conditionalForwarder.MasterServers.Split(';')) {  
                Add-DnsServerConditionalForwarderZone -ComputerName $serverName -Name $conditionalForwarder.Name -MasterServers $conditionalForwarder.MasterServers -PassThru -ErrorAction SilentlyContinue | Out-Null  
            }  
        }  
    }  
  
    # Configure secondary zones  
    if (Test-Path $secondaryZonesPath) {  
        $secondaryZones = Import-Csv -Path $secondaryZonesPath  
        foreach ($secondaryZone in $secondaryZones) {  
            $currentSecondaryZone = Get-DnsServerZone -ComputerName $serverName -Name $secondaryZone.Name -ZoneType Secondary -ErrorAction SilentlyContinue  
            if ($null -eq $currentSecondaryZone -or Compare-Object -ReferenceObject $currentSecondaryZone.MasterServers -DifferenceObject $secondaryZone.MasterServers.Split(';')) {  
                Add-DnsServerSecondaryZone -ComputerName $serverName -Name $secondaryZone.Name -MasterServers $secondaryZone.MasterServers -PassThru -ErrorAction SilentlyContinue | Out-Null  
            }  
        }  
    }  
  
    # Configure root hints  
    if (Test-Path $rootHintsPath) {  
        $rootHints = Import-Csv -Path $rootHintsPath  
        foreach ($rootHint in $rootHints) {  
            $currentRootHint = Get-DnsServerRootHint -ComputerName $serverName | Where-Object { $_.NameServer -eq $rootHint.NameServer }  
            if ($null -eq $currentRootHint -or $currentRootHint.InterfaceIPAddress.ToString() -ne $rootHint.IPAddress) {  
                Set-DnsServerRootHint -ComputerName $serverName -NameServer $rootHint.NameServer -IPAddress $rootHint.IPAddress -PassThru -ErrorAction SilentlyContinue | Out-Null  
            }  
        }  
    }  
  
    # Configure delegations  
    if (Test-Path $delegationsPath) {  
        $delegations = Import-Csv -Path $delegationsPath  
        foreach ($delegation in $delegations) {  
            # Delegations are more complex to check, so we'll just reapply the configuration  
            Add-DnsServerZoneDelegation -ComputerName $serverName -ChildZoneName $delegation.ChildZoneName -NameServer $delegation.NameServer -IPAddress $delegation.IPAddress -ParentZoneName $delegation.ParentZoneName -PassThru -ErrorAction SilentlyContinue | Out-Null  
        }  
    }  
  
    # Configure stub zones  
    if (Test-Path $stubZonesPath) {  
        $stubZones = Import-Csv -Path $stubZonesPath  
        foreach ($stubZone in $stubZones) {  
            $currentStubZone = Get-DnsServerZone -ComputerName $serverName -Name $stubZone.Name -ZoneType Stub -ErrorAction SilentlyContinue  
            if ($null -eq $currentStubZone -or Compare-Object -ReferenceObject $currentStubZone.MasterServers -DifferenceObject $stubZone.MasterServers.Split(';')) {  
                Add-DnsServerStubZone -ComputerName $serverName -Name $stubZone.Name -MasterServers $stubZone.MasterServers -PassThru -ErrorAction SilentlyContinue | Out-Null  
            }  
        }  
    }  
}  
  
# Output completion message  
Write-Host "DNS configurations have been checked and updated as necessary on all specified servers."  
