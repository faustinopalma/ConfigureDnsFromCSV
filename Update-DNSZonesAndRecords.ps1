# parameters to enable part of the script
param (
    [switch]$doPrimaryZones = $false,
    [switch]$doDelegations = $false,
    [switch]$doStubZones = $false,
    [switch]$doARecords = $false
)


# Define the path to the dns-configs folder  
$dnsConfigsPath = Join-Path -Path $PSScriptRoot -ChildPath "dns-configs"  

# Adding the current server name to the config path to take the configuration related to the server from which the script is executed.
$serverName = $env:computername  
$serverFolderPath = Join-Path -Path $dnsConfigsPath -ChildPath $serverName


# Define the path to the CSV files for the current server
$primaryZonesPath = Join-Path -Path $serverFolderPath -ChildPath "primary_zones.csv"
$delegationsPath = Join-Path -Path $serverFolderPath -ChildPath "delegations.csv"  
$stubZonesPath = Join-Path -Path $serverFolderPath -ChildPath "stub_zones.csv"

# Configure primary zones replication scope
if ($doPrimaryZones -and (Test-Path $primaryZonesPath)) {
    Write-Output "===> EXECUTING CONFIG ON PRIMARY ZONES"
    $primaryZones = Import-Csv -Path $primaryZonesPath  
    foreach ($primaryZone in $primaryZones) {
        if (Get-DnsServerZone -Name $primaryZone.Name -ErrorAction SilentlyContinue) {
            Set-DnsServerPrimaryZone -Name $primaryZone.Name -ReplicationScope $primaryZone.ReplicationScope
        } else {
            Add-DnsServerPrimaryZone -Name $primaryZone.Name -ReplicationScope $primaryZone.ReplicationScope
        }
    }
    Write-Output "primary zones configured as follows"
    foreach ($primaryZone in $primaryZones) {
        $primaryZoneAsSet = Get-DnsServerZone -Name $primaryZone.Name -ErrorAction SilentlyContinue
        Write-Output ($primaryZoneAsSet | Select-Object -Property ZoneName, IsDsIntegrated, ReplicationScope)
        # Write-Output ($primaryZoneAsSet | ConvertTo-Json)
    }
    Write-Output "`n"
}


# Configure delegations  
if ($doDelegations -and (Test-Path $delegationsPath)) {
    write-output "===> EXECUTING CONFIG ON DELEGATIONS" 
    $delegations = Import-Csv -Path $delegationsPath  
    foreach ($delegation in $delegations) {  
        # Assuming the CSV has columns named 'ChildZoneName', 'NameServer', 'IPAddress', and 'ParentZoneName'  
        Add-DnsServerZoneDelegation -ChildZoneName $delegation.ChildZoneName -NameServer $delegation.NameServer -IPAddress $delegation.IPAddress -Name $delegation.ParentZoneName  
    }
    Write-Output "`n"
}

# Configure stub zones  
if ($doStubZones -and (Test-Path $stubZonesPath)) {
    write-output "===> EXECUTING CONFIG ON STUB ZONES"
    $stubZones = Import-Csv -Path $stubZonesPath  
    foreach ($stubZone in $stubZones) {
        if (Get-DnsServerZone -Name $stubZone.Name -ErrorAction SilentlyContinue) {
            Remove-DnsServerZone -Name $stubZone.Name -Force
        }
        # Assuming the CSV has columns named 'Name' and 'MasterServers'  
        Add-DnsServerStubZone -Name $stubZone.Name -MasterServers $stubZone.MasterServers.Split(';')
    }
    Write-Output "`n"
}

$primaryZones_A_recors_Path = Join-Path -Path $serverFolderPath -ChildPath "primaryZones" -AdditionalChildPath $primaryZone.Name, "records_A.csv"
if ($doARecords -and (Test-Path $primaryZones_A_recors_Path)) {
    Write-Output "===> EXECUTING CONFIG ON A RECORDS"
    $A_records = Import-Csv -Path $primaryZones_A_recors_Path
    foreach ($A_record in $A_records) {
        Add-DnsServerResourceRecordA -ZoneName $primaryZone.Name -Name $A_record.Name -IPv4Address $A_record.IPv4Address -CreatePtr
    }
    Write-Output "`n"
}




# items to automate:
# 1, forwarders must match csv entries with order
# 2, seconday zones to be added if not existing and changed if existing (no deletion of zones that are not in csv)
# 3, conditional forwarders to be added for those that are not active directory integrated


# reverse zones will be migrated manually 

# test reverse commit

# health check reale sui record che sono scritti in un csv. script che da una macchina fa query dns per ogni zona che amministro e invio a nagios un log con esito positivo o negativo
# prende il write output e il return code. descrizione e tipologia di errore.
# script eseguito sulle macchine che fanno check del dns su se stesse.


# come svecchiare le zone a mano prima di attivare lo scaveging. 