<#  
.SYNOPSIS  
This PowerShell script configures a DNS server with various settings based on input from CSV files.  
  
.DESCRIPTION  
Each CSV file should be formatted with specific columns that correspond to the DNS settings being configured.  
Below are the expected formats for each CSV file:  
  
1. forwarders.csv - Global forwarders for the DNS server.  
   Format:  
   IPAddress  
   8.8.8.8  
   8.8.4.4  
   Each line after the header should contain one IP address of a forwarder DNS server.  
  
2. conditional_forwarders.csv - Conditional forwarders.  
   Format:  
   Domain,ForwarderIPs  
   example.com,"192.0.2.10;192.0.2.11"  
   anotherdomain.com,"203.0.113.5;203.0.113.6"  
   The 'Domain' column contains the domain name for the conditional forwarder.  
   The 'ForwarderIPs' column contains the IP addresses of the DNS servers for the conditional forwarder,  
   separated by semicolons.  
  
3. secondary_zones.csv - Secondary zones.  
   Format:  
   ZoneName,MasterServers  
   example.com,"192.0.2.10;192.0.2.11"  
   The 'ZoneName' column contains the name of the secondary zone.  
   The 'MasterServers' column contains the IP addresses of the master DNS servers for the zone, separated by semicolons.  
  
4. root_hints.csv - Root hints.  
   Format:  
   HostName,IPAddress  
   ns1.example.com,192.0.2.10  
   ns2.example.com,192.0.2.11  
   The 'HostName' column contains the fully qualified domain name of the root hint server.  
   The 'IPAddress' column contains the IP address of the root hint server.  
  
5. delegations.csv - Delegations.  
   Format:  
   ChildZone,NameServer,NameServerIP  
   child.example.com,ns1.child.example.com,192.0.2.10  
   The 'ChildZone' column contains the name of the zone that is being delegated.  
   The 'NameServer' column contains the FQDN of the delegated name server for the child zone.  
   The 'NameServerIP' column contains the IP address of the delegated name server.  
  
6. stub_zones.csv - Stub zones.  
   Format:  
   ZoneName,MasterServers  
   stub.example.com,"192.0.2.10;192.0.2.11"  
   The 'ZoneName' column contains the name of the stub zone.  
   The 'MasterServers' column contains the IP addresses of the DNS servers that host the zone, separated by semicolons.  
  
Each CSV file must be placed in the appropriate path before running this script. The script will import the settings  
from the CSV files and apply them to the DNS server configuration. It will also check for existing configurations  
and update them if necessary.  
 
.EXAMPLE  
C:\PS> .\Configure-DnsServerFromCsv.ps1  
  
This example runs the script to configure the DNS server based on the provided CSV files.  
  
.NOTES  
Make sure to run this script with administrative privileges.  
Adjust the CSV file paths as necessary before running the script.  
Each CSV file must be formatted correctly for the script to work.  
#> 
  
# Install DNS Server role if not present  
If ((Get-WindowsFeature -Name 'DNS').InstallState -ne 'Installed') {  
    Install-WindowsFeature -Name 'DNS' -IncludeManagementTools  
    Write-Host "DNS Server role has been installed."  
} Else {  
    Write-Host "DNS Server role is already installed."  
}  
  
# Define the path to the CSV files  
#$forwardersCsv = 'C:\path\to\forwarders.csv'  
#$conditionalForwardersCsv = 'C:\path\to\conditional_forwarders.csv'  
#$secondaryZonesCsv = 'C:\path\to\secondary_zones.csv'  
#$rootHintsCsv = 'C:\path\to\root_hints.csv'  
#$delegationsCsv = 'C:\path\to\delegations.csv'  
#$stubZonesCsv = 'C:\path\to\stub_zones.csv'  

# Define the path to the CSV files using $PSScriptRoot  
$forwardersCsv = Join-Path $PSScriptRoot 'forwarders.csv'  
$conditionalForwardersCsv = Join-Path $PSScriptRoot 'conditional_forwarders.csv'  
$secondaryZonesCsv = Join-Path $PSScriptRoot 'secondary_zones.csv'  
$rootHintsCsv = Join-Path $PSScriptRoot 'root_hints.csv'  
$delegationsCsv = Join-Path $PSScriptRoot 'delegations.csv'  
$stubZonesCsv = Join-Path $PSScriptRoot 'stub_zones.csv' 

  
# Function to configure global forwarders  
Function Configure-GlobalForwarders {  
    Param ($csvPath)  
    $currentForwarders = (Get-DnsServerForwarder).IPAddress | Sort-Object  
    $csvForwarders = Import-Csv -Path $csvPath | ForEach-Object { $_.IPAddress } | Sort-Object  
  
    If (Compare-Object -ReferenceObject $currentForwarders -DifferenceObject $csvForwarders) {  
        Set-DnsServerForwarder -IPAddress $csvForwarders  
        Write-Host "Global forwarders updated to: $($csvForwarders -join ', ')"  
    } Else {  
        Write-Host "Global forwarders are already set correctly."  
    }  
}  
  
# Function to configure conditional forwarders  
Function Configure-ConditionalForwarders {  
    Param ($csvPath)  
    $conditionalForwarders = Import-Csv -Path $csvPath  
  
    foreach ($entry in $conditionalForwarders) {  
        $forwarderIPs = $entry.ForwarderIPs -split ';'  
        $existingForwarder = Get-DnsServerZone -Name $entry.Domain -ErrorAction SilentlyContinue | Where-Object { $_.ZoneType -eq "ConditionalForwarder" }  
  
        if ($existingForwarder) {  
            $existingIPs = $existingForwarder.MasterServers | Sort-Object  
            if (Compare-Object -ReferenceObject $existingIPs -DifferenceObject $forwarderIPs) {  
                Set-DnsServerConditionalForwarderZone -Name $entry.Domain -MasterServers $forwarderIPs  
                Write-Host "Updated conditional forwarder for domain $($entry.Domain)"  
            } Else {  
                Write-Host "Conditional forwarder for domain $($entry.Domain) is already set correctly."  
            }  
        } else {  
            Add-DnsServerConditionalForwarderZone -Name $entry.Domain -MasterServers $forwarderIPs  
            Write-Host "Added conditional forwarder for domain $($entry.Domain)"  
        }  
    }  
}  
  
# Function to configure secondary zones  
Function Configure-SecondaryZones {  
    Param ($csvPath)  
    $secondaryZones = Import-Csv -Path $csvPath  
  
    foreach ($entry in $secondaryZones) {  
        $masterServers = $entry.MasterServers -split ';'  
        $existingZone = Get-DnsServerZone -Name $entry.ZoneName -ErrorAction SilentlyContinue  
  
        if ($existingZone -and $existingZone.ZoneType -eq 'Secondary') {  
            $existingMasters = $existingZone.MasterServers | Sort-Object  
            if (Compare-Object -ReferenceObject $existingMasters -DifferenceObject $masterServers) {  
                Set-DnsServerSecondaryZone -Name $entry.ZoneName -MasterServers $masterServers  
                Write-Host "Updated secondary zone for $($entry.ZoneName)"  
            } Else {  
                Write-Host "Secondary zone for $($entry.ZoneName) is already set correctly."  
            }  
        } else {  
            Add-DnsServerSecondaryZone -Name $entry.ZoneName -MasterServers $masterServers  
            Write-Host "Added secondary zone for $($entry.ZoneName)"  
        }  
    }  
}  
  
# Function to configure root hints  
Function Configure-RootHints {  
    Param ($csvPath)  
    $csvRootHints = Import-Csv -Path $csvPath  
  
    foreach ($entry in $csvRootHints) {  
        $existingRootHint = Get-DnsServerRootHint -ErrorAction SilentlyContinue | Where-Object { $_.NameHost -eq $entry.HostName }  
  
        if ($existingRootHint) {  
            if ($existingRootHint.InterfaceIPAddress -ne $entry.IPAddress) {  
                Set-DnsServerRootHint -NameHost $entry.HostName -InterfaceIPAddress $entry.IPAddress  
                Write-Host "Updated root hint for $($entry.HostName)"  
            } Else {  
                Write-Host "Root hint for $($entry.HostName) is already set correctly."  
            }  
        } else {  
            Add-DnsServerRootHint -NameHost $entry.HostName -InterfaceIPAddress $entry.IPAddress  
            Write-Host "Added root hint for $($entry.HostName)"  
        }  
    }  
}  
  
# Function to configure delegations  
Function Configure-Delegations {  
    Param ($csvPath)  
    $delegations = Import-Csv -Path $csvPath  
  
    foreach ($entry in $delegations) {  
        # Delegations are more complex and may require additional logic to handle properly.  
        # Here is a simplified version to demonstrate the concept.  
        $zone = Get-DnsServerZone -Name $entry.ChildZone -ErrorAction SilentlyContinue  
        if ($zone) {  
            Add-DnsServerZoneDelegation -Name $entry.ChildZone -ChildZoneName $entry.NameServer -NameServer $entry.NameServer -IPAddress $entry.NameServerIP  
            Write-Host "Delegation added for $($entry.ChildZone) to $($entry.NameServer) with IP $($entry.NameServerIP)"  
        } else {  
            Write-Host "Parent zone for $($entry.ChildZone) not found. Delegation cannot be created."  
        }  
    }  
}  
  
# Function to configure stub zones  
Function Configure-StubZones {  
    Param ($csvPath)  
    $stubZones = Import-Csv -Path $csvPath  
  
    foreach ($entry in $stubZones) {  
        $masterServers = $entry.MasterServers -split ';'  
        $existingZone = Get-DnsServerZone -Name $entry.ZoneName -ErrorAction SilentlyContinue  
  
        if ($existingZone -and $existingZone.ZoneType -eq 'Stub') {  
            $existingMasters = $existingZone.MasterServers | Sort-Object  
            if (Compare-Object -ReferenceObject $existingMasters -DifferenceObject $masterServers) {  
                Set-DnsServerStubZone -Name $entry.ZoneName -MasterServers $masterServers  
                Write-Host "Updated stub zone for $($entry.ZoneName)"  
            } Else {  
                Write-Host "Stub zone for $($entry.ZoneName) is already set correctly."  
            }  
        } else {  
            Add-DnsServerStubZone -Name $entry.ZoneName -MasterServers $masterServers  
            Write-Host "Added stub zone for $($entry.ZoneName)"  
        }  
    }  
}  
  
# Check if the CSV files exist and call the configuration functions  
If (Test-Path -Path $forwardersCsv) {  
    Configure-GlobalForwarders -csvPath $forwardersCsv  
} Else {  
    Write-Host "The forwarders CSV file was not found."  
}  
  
If (Test-Path -Path $conditionalForwardersCsv) {  
    Configure-ConditionalForwarders -csvPath $conditionalForwardersCsv  
} Else {  
    Write-Host "The conditional forwarders CSV file was not found."  
}  
  
If (Test-Path -Path $secondaryZonesCsv) {  
    Configure-SecondaryZones -csvPath $secondaryZonesCsv  
} Else {  
    Write-Host "The secondary zones CSV file was not found."  
}  
  
If (Test-Path -Path $rootHintsCsv) {  
    Configure-RootHints -csvPath $rootHintsCsv  
} Else {  
    Write-Host "The root hints CSV file was not found."  
}  
  
If (Test-Path -Path $delegationsCsv) {  
    Configure-Delegations -csvPath $delegationsCsv  
} Else {  
    Write-Host "The delegations CSV file was not found."  
}  
  
If (Test-Path -Path $stubZonesCsv) {  
    Configure-StubZones -csvPath $stubZonesCsv  
} Else {  
    Write-Host "The stub zones CSV file was not found."  
}  
  
Write-Host "DNS server configuration is complete."  
