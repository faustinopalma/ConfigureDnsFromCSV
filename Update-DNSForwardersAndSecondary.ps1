# parameters to enable part of the script
param (
    [switch]$doForwarders = $false,
    [switch]$doConditionalForwarders = $false,
    [switch]$doSecondaryZones = $false
)


# Define the path to the dns-configs folder
$dnsConfigsPath = Join-Path -Path $PSScriptRoot -ChildPath "dns-configs"

# Adding the current server name to the config path to take the configuration related to the server from which the script is executed.
$serverName = $env:computername
$serverFolderPath = Join-Path -Path $dnsConfigsPath -ChildPath $serverName


# Define the path to the CSV files for the current server
$forwardersPath = Join-Path -Path $serverFolderPath -ChildPath "forwarders.csv"
$conditionalForwardersPath = Join-Path -Path $serverFolderPath -ChildPath "conditional_forwarders.csv"
$secondaryZonesPath = Join-Path -Path $serverFolderPath -ChildPath "secondary_zones.csv"

# Configure forwarders
if ($doForwarders -and (Test-Path $forwardersPath)) {
    Write-Output "===> EXECUTING CONFIG ON FORWARDERS"
    $forwarders = Import-Csv -Path $forwardersPath
    $currentForwarders = (Get-DnsServerForwarder).IPAddress.IPAddressToString

    foreach ($forwarder in $currentForwarders) {
        Remove-DnsServerForwarder -IPAddress $forwarder -Force
    }

    foreach ($forwarder in $forwarders) {
        # Assuming the CSV has a column named 'IPAddress'
        Add-DnsServerForwarder -IPAddress $forwarder.IPAddress
    }
    $currentForwarders = (Get-DnsServerForwarder).IPAddress.IPAddressToString
    Write-Output "forwarders configured as follows"
    Write-Output ($currentForwarders)

    Write-Output "`n"
}

# Configure conditional forwarders
if ($doConditionalForwarders -and (Test-Path $conditionalForwardersPath)) {
    write-output "===> EXECUTING CONFIG ON CONDITIONAL FORWARDERS"
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
    Write-Output "`n"
}

# Configure secondary zones
if ($doSecondaryZones -and (Test-Path $secondaryZonesPath)) {
    write-output "===> EXECUTING CONFIG ON SECONDARY ZONES"
    $secondaryZones = Import-Csv -Path $secondaryZonesPath
    foreach ($secondaryZone in $secondaryZones) {
        if (Get-DnsServerZone -Name $secondaryZone.Name -ErrorAction SilentlyContinue) {
            Remove-DnsServerZone -Name $secondaryZone.Name -Force
        }
        # Assuming the CSV has columns named 'Name', 'MasterServers', and 'ZoneFile'
        Add-DnsServerSecondaryZone -Name $secondaryZone.Name -MasterServers $secondaryZone.MasterServers.Split(';') -ZoneFile $secondaryZone.ZoneFile
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