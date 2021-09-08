# Part 2: LogicMonitor PowerShell Module Example Uses

## Bulk trigger Active Discovery for a group of devices

```powershell

#Method One
#Using Get-LMDeviceGroupDevices to trigger AD on a folder called Eastbridge
$deviceGroupId = (Get-LMDeviceGroup -Name "Eastbridge").id
Get-LMDeviceGroupDevices -Id $deviceGroupId | Foreach-Object {Invoke-LMActiveDiscovery -Id $_.id}

#Method Two
#Using Get-LMDevice to get a filtered list of devices to trigger AD against
Get-LMDevice -Name "lm*" | Foreach-Object {Invoke-LMActiveDiscovery -Id $_.id}

#Method Three
#Using the parameter in the Invoke-LMActiveDiscovery to trigger AD on a folder called Eastbridge
Invoke-LMActiveDiscovery -GroupName "Eastbridge"
```

## Rename devices based on value of a given property

```powershell
#Method One
#Using Get-LMDeviceProperty to retrieve the value for sysname and Set-LMDevice to set the new displayName for it
$deviceProperty = (Get-LMDeviceProperty -Name "192.168.1.1" -Filter @{name="system.sysname"}).value
Set-LMDevice -Name "192.168.1.1" -DisplayName $deviceProperty

#Method Two
#Using Get-LMDevice to retrieve the value for sysname and Set-LMDevice to set the new displayName
$device = Get-LMDevice -Name "192.168.1.1"
$deviceProperty = ($device.systemProperties[$device.systemProperties.name.IndexOf("system.sysname")].value)
Set-LMDevice -Name "192.168.1.1" -DisplayName $deviceProperty

```

## CSV import a list of groups for auto creation

```powershell
#Method 1:
#Import new device groups from CSV with no properties
#
#   Example CSV:
#   parent_folder,name,description
#   "portalname","Locations","All Resources"
#   "Locations","NA","North America Resources"
#   "Locations","EURO","Europe Resources"
#   "Locations","APAC","Asia Pacific Resources"
#
$csvPath = "../LogicMonitor_Scripts/PowerShell Basics/Example-GroupImport.csv"
Import-Csv -Path $csvPath | Foreach-Object {New-LMDeviceGroup -Name $_.name -ParentGroupName $_.parent_folder -Description $_.description}

}

#Method 2:
#Import new device groups from CSV including properties
#
#   Example CSV:
#   parent_folder,name,description,properties
#   "portalname","Locations","All Resources",""
#   "Locations","NA","North America Resources","snmp.community=na-snmp"
#   "Locations","EURO","Europe Resources","snmp.community=euro-snmp"
#   "Locations","APAC","Asia Pacific Resources","snmp.community=apac-snmp"
#
$csvPath = "../LogicMonitor_Scripts/PowerShell Basics/Example-GroupImport.csv"
$groups = Import-Csv -Path $csvPath
foreach($group in $groups){
    #Break properties into hashtable
    $properties = @{}
    $group.properties.Split(",").Replace("\","\\") | ConvertFrom-StringData | ForEach-Object {$properties += $_}

    #Create new device group in LM
    New-LMDeviceGroup -Name $group.name -ParentGroupName $group.parent_folder -Description $group.description -properties $properties
}
```
