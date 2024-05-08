# Define the path to the dns-configs folder  
$dnsConfigsPath = Join-Path -Path $PSScriptRoot -ChildPath "dns-configs"  

$serverName = $env:computername  
$serverFolderPath = Join-Path -Path $dnsConfigsPath -ChildPath $serverName


# Define the path to the CSV files for the current server
$primaryZonesPath = Join-Path -Path $serverFolderPath -ChildPath "primary_zones.csv"
$forwardersPath = Join-Path -Path $serverFolderPath -ChildPath "forwarders.csv"  
$conditionalForwardersPath = Join-Path -Path $serverFolderPath -ChildPath "conditional_forwarders.csv"  
$secondaryZonesPath = Join-Path -Path $serverFolderPath -ChildPath "secondary_zones.csv"  
$delegationsPath = Join-Path -Path $serverFolderPath -ChildPath "delegations.csv"  
$stubZonesPath = Join-Path -Path $serverFolderPath -ChildPath "stub_zones.csv"

# Configure primary zones replication scope
if (Test-Path $primaryZonesPath) {  
    $primaryZones = Import-Csv -Path $primaryZonesPath  
    foreach ($primaryZone in $primaryZones) {
        if (Get-DnsServerZone -Name $primaryZone.Name -ErrorAction SilentlyContinue) {
            Set-DnsServerPrimaryZone -Name $primaryZone.Name -ReplicationScope $primaryZone.ReplicationScope
        } else {
            Add-DnsServerPrimaryZone -Name $primaryZone.Name -ReplicationScope $primaryZone.ReplicationScope
        }
    }
}

# Configure forwarders  
if (Test-Path $forwardersPath) {  
    $forwarders = Import-Csv -Path $forwardersPath
    
    $currentForwarders = (Get-DnsServerForwarder).IPAddress | Sort-Object  
    $desiredForwarders = $forwarders.IPAddress | Sort-Object

    if (($currentForwarders.IPAddressToString | ConvertTo-Json) -eq ($desiredForwarders | ConvertTo-Json)) {
        Write-Output "forwarders are configured and are equal"
    }

    foreach ($forwarder in $currentForwarders) {
        Remove-DnsServerForwarder -IPAddress $forwarder.IPAddressToString -Force
    }

    foreach ($forwarder in $forwarders) {  
        # Assuming the CSV has a column named 'IPAddress'  
        Add-DnsServerForwarder -IPAddress $forwarder.IPAddress  
    }  
}   

# Configure conditional forwarders  
if (Test-Path $conditionalForwardersPath) {  
    $conditionalForwarders = Import-Csv -Path $conditionalForwardersPath
    foreach ($conditionalForwarder in $conditionalForwarders) {
        # Assuming the CSV has columns named 'Name' and 'MasterServers'
        if (Get-DnsServerZone -Name $conditionalForwarder.Name -ErrorAction SilentlyContinue) {
            $DnsServerZone = Get-DnsServerZone -Name $conditionalForwarder.Name
            if (($DnsServerZone.MasterServers.IPAddressToString | ConvertTo-Json) -eq ($conditionalForwarder.MasterServers.Split(';') | ConvertTo-Json)) {
                Write-Output "conditional forwarders are set and equal to the required config"
            } else {
                Write-Output "conditional forwarders are set but are NOT equal to the required config"
            }
            Set-DnsServerConditionalForwarderZone -Name $conditionalForwarder.Name -MasterServers $conditionalForwarder.MasterServers.Split(';')
        } else {
            Add-DnsServerConditionalForwarderZone -Name $conditionalForwarder.Name -MasterServers $conditionalForwarder.MasterServers.Split(';')
        }
    }  
}

# Configure secondary zones  
if (Test-Path $secondaryZonesPath) {  
    $secondaryZones = Import-Csv -Path $secondaryZonesPath  
    foreach ($secondaryZone in $secondaryZones) {
        if (Get-DnsServerZone -Name $secondaryZone.Name -ErrorAction SilentlyContinue) {
            Remove-DnsServerZone -Name $secondaryZone.Name -Force
        }
        # Assuming the CSV has columns named 'Name', 'MasterServers', and 'ZoneFile'  
        Add-DnsServerSecondaryZone -Name $secondaryZone.Name -MasterServers $secondaryZone.MasterServers.Split(';') -ZoneFile $secondaryZone.ZoneFile
    }  
}


# Configure delegations  
if (Test-Path $delegationsPath) {  
    $delegations = Import-Csv -Path $delegationsPath  
    foreach ($delegation in $delegations) {  
        # Assuming the CSV has columns named 'ChildZoneName', 'NameServer', 'IPAddress', and 'ParentZoneName'  
        Add-DnsServerZoneDelegation -ChildZoneName $delegation.ChildZoneName -NameServer $delegation.NameServer -IPAddress $delegation.IPAddress -Name $delegation.ParentZoneName  
    }  
}  


# Configure delegations  
if (Test-Path $delegationsPath) {  
    $delegations = Import-Csv -Path $delegationsPath  
    foreach ($delegation in $delegations) {  
        # Assuming the CSV has columns named 'ChildZoneName', 'NameServer', 'IPAddress', and 'ParentZoneName'  
        Add-DnsServerZoneDelegation -ChildZoneName $delegation.ChildZoneName -NameServer $delegation.NameServer -IPAddress $delegation.IPAddress -Name $delegation.ParentZoneName  
    }  
} 

# Configure stub zones  
if (Test-Path $stubZonesPath) {  
    $stubZones = Import-Csv -Path $stubZonesPath  
    foreach ($stubZone in $stubZones) {
        if (Get-DnsServerZone -Name $stubZone.Name -ErrorAction SilentlyContinue) {
            Remove-DnsServerZone -Name $stubZone.Name -Force
        }
        # Assuming the CSV has columns named 'Name' and 'MasterServers'  
        Add-DnsServerStubZone -Name $stubZone.Name -MasterServers $stubZone.MasterServers.Split(';')
    }  
}
$primaryZones_A_recors_Path = Join-Path -Path $serverFolderPath -ChildPath "primaryZones" -AdditionalChildPath $primaryZone.Name, "records_A.csv"
if (Test-Path $primaryZones_A_recors_Path) {
    $A_records = Import-Csv -Path $primaryZones_A_recors_Path
    foreach ($A_record in $A_records) {
        Add-DnsServerResourceRecordA -ZoneName $primaryZone.Name -Name $A_record.Name -IPv4Address $A_record.IPv4Address -CreatePtr
    }
} else {
    Write-Output "zone path NOT found for $($primaryZone.Name)"
}



  
# Output completion message  
Write-Host "DNS configurations have been applied to all specified servers."  


# items to automate:
# 1, forwarders must match csv entries with order
# 2, seconday zones to be added if not existing and changed if existing (no deletion of zones that are not in csv)
# 3, conditional forwarders to be added for those that are not active directory integrated

# reverse zones will be migrated manually 

# test reverse commit
