# PowerShell basics, working with objects

# Select-Object (alias select)

The `Select-Object` cmdlet "filters" various properties from being returned to the PowerShell pipeline. To "filter” object properties from being returned, you can use the Property parameter and specify a comma-delimited set of one or more properties to return.

```powershell
Command:
Get-LMPortalInfo | Select-Object -Property companyDisplayName,numberOfOpenAlerts,numberOfDevices

Output:
#companyDisplayName numberOfOpenAlerts numberOfDevices
#------------------ ------------------ ---------------
#lmstevenvillardi                   30              16
```

#Sort-Object (alias sort)

The `Sort-Object` cmdlet allows you to collect all of the objects returned and then output them in the order you define. For example, using the Property parameter of `Sort-Object`, you can specify one or more properties on the incoming objects from Get-LMDevice to sort by. PowerShell will pass each object to the `Sort-Object` cmdlet and then return them sorted by the value of the property.

```powershell
Command:
Get-LMDevice | Select-Object id,name,displayName,deviceType | Sort-Object displayName

Output:
#id name                        displayName                    deviceType
#-- ----                        -----------                    ----------
#50 LMAZUREACCOUNT-157          Azure Account                           4
# 8 status.azure.com            Azure AD                                0
#80 LMSAASACCOUNT-399           Cloudflare Account                     10
#48 gsuite.google.com           G Suite                                 0
#79 LMSAASACCOUNT-398           Github Account                         10
#41 HPB1A0E5                    HPB1A0E5                                0
#39 127.0.0.1                   LM-COLL01                               0
# 1 172.31.33.72                lmstevenvillardi-linuxcol01             0
# 2 127.0.0.1                   lmstevenvillardi-wincol01               0
# 5 logicmonitor.com            LogicMonitor                            0
#47 192.168.1.14                Macbook                                 0
#40 192.168.1.1                 Netgear Wireless Router DD-WRT          0
# 3 outlook.office365.com       Office365 - Updated                     0
#57 LMSAASACCOUNT-355           Office365 Test Account                 10
# 4 status.slack.com            Slack                                   0
#81 status.ringcentral.com      status.ringcentral.com                  0
#72 wmi01.logicmonitor.internal wmi01.logicmonitor.internal             0
```

#Group-Object (alias group)

The `Group-Object` cmdlet displays objects in groups based on the value of a specified property. `Group-Object` returns a table with one row for each property value and a column that displays the number of items with that value.

If you specify more than one property, `Group-Object` first groups them by the values of the first property, and then, within each property group, it groups by the value of the next property.

```powershell
Command:
Get-LMAlert  -ClearedAlerts $true | Group-Object -Property resourceTemplateName

Output:
#Count Name                                     Group
#----- ----                                     -----
#   44 Azure Service Health                     ...trimed...
#   17 DNS Check                                ...trimed...
#  256 Host Status                              ...trimed...
#    2 HTTP                                     ...trimed...
#    1 HTTPS                                    ...trimed...
#    8 Office365 Service Health                 ...trimed...
#  396 Ping                                     ...trimed...
#    6 RingCentral Service Health               ...trimed...
# 2876 Statuspage.IO Status                     ...trimed...
#    2 System Uptime                            ...trimed...
#   29 website                                  ...trimed...
#    7 Windows Check Remote File - Example      ...trimed...
#    2 Windows Events LM Logs                   ...trimed...
#    3 Windows System Event Log                 ...trimed...
```

#Where-Object (alias ?)

While the `Select-Object` cmdlet limits the output of specific properties, the Where-Object cmdlet limits the output of entire objects.

The `Where-Object` cmdlet is similar in function to the SQL WHERE clause. It acts as a filter of the original source to only return certain objects that match a specific criteria. You specify the criteria in your where clause using a script block `{where clause criteria}`. You can reference the object in the pipeline using the `$_` variable.

Perhaps you’ve decided that you only want objects returned with a deviceType property value of **0** and only those with a **DisplayName** property value that begins with **LM**

```powershell
Command:
Get-LMDevice | Where-Object {$_.displayName -like "lm*" -and $_.deviceType -eq 0} | Select-Object -Property id,name,displayName,deviceType

Output:
#id name         displayName                 deviceType
#-- ----         -----------                 ----------
# 1 172.31.33.72 lmstevenvillardi-linuxcol01          0
# 2 127.0.0.1    lmstevenvillardi-wincol01            0
#39 127.0.0.1    LM-COLL01                            0
```

#ForEach-Object (alias %)

As each object is processed via the pipeline, you can take action on each object with a loop. The `ForEach-Object` cmdlet allows you to take action on each object flowing into it. An example would be getting a list of devices that match a specifc criteria and performing some action on them like updating a desciprtion value for a set of devices.

```powershell
Command:
$devices = Get-LMDevice | Where-Object {$_.displayName -like "lm*" -and $_.deviceType -eq 0} | Select-Object -Property id,name,displayName,deviceType
$devices | ForEach-Object {Set-LMDevice -id $_.id -Description "Updated description"} | Select-Object id,name,displayName,description

Output:
#id name         displayName                 description
#-- ----         -----------                 -----------
# 1 172.31.33.72 lmstevenvillardi-linuxcol01 Updated description
# 2 127.0.0.1    lmstevenvillardi-wincol01   Updated description
#39 127.0.0.1    LM-COLL01                   Updated description
```
