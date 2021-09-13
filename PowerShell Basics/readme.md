# Part 1: Intro to PowerShell

PowerShell is mainly suited for Windows operating system. It is used to automate tasks on windows OS. As PowerShell is built on top of .NET framework, that is why it can perform any task on a windows machine. In 2018 Microsoft released PowerShell Core which allows for PowerShell to run cross-platform on Windows/Linux/MacOS

## Programmming vs Scripting

Python/Groovy are examples of general-purpose programming/scripting languages, whereas PowerShell is a scripting language and an automation tool. The major difference between a programming and scripting language is that a programming language uses a compiler to convert high-level language to machine language, whereas a scripting language uses an interpreter. The compiler compiles the complete code, whereas the interpreter compiles line by line.

Since PowerShell uses an interpreter as opposed to being compiled it makes it ideal for scripting as it allows for testing directly in commandline one line at a time as opposed to ensuring an entire script compiles successfully before even attempting to run.

This makes PowerShell an ideal condidate for automatation and scripting tasks for System Administrators.

# Installing PowerShell Core 7.1

## Windows

Since PowerShell is natively installed on Windows, there is no installation needed to start using PowerShell unless you want to run the latest core version alongside the version Windows ships with (usually 5.1).

Install the latest version of PowerShell Core on Windows:

```powershell
#Execute the msi file from the Direct Downloads link
./PowerShell-7.1.4-win-x64.msi
```

[Direct Download for Windows](https://github.com/PowerShell/PowerShell/releases/download/v7.1.4/PowerShell-7.1.4-win-x64.msi)

## MacOS

If you have brew installed on your mac you can simply run:

```sh
#Install PowerShell
brew install --cask powershell

#Start PowerShell
pwsh
```

If you do not have brew installed you can download the direct pkg file and instal normally using this link: [Download Powershell Core for MacOS](https://github.com/PowerShell/PowerShell/releases/download/v7.1.4/powershell-7.1.4-osx-x64.pkg)

## Linux

See the PowerShell releases page for the appropirate package for your flavor or linux: [Download PowerShell Core for Linux](https://github.com/PowerShell/PowerShell/releases/tag/v7.1.4)

Example to install for Ubuntu 20.4:

```sh
#Install download deb file
sudo dpkg -i powershell_7.1.4-1.ubuntu.20.04_amd64.deb
sudo apt-get install -f

#Start PowerShell
pwsh
```

Example to install for CentOS/RHEL7:

```sh
# Register the Microsoft RedHat repository
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo

# Install PowerShell
sudo yum install -y powershell

# Start PowerShell
pwsh
```

# PowerShell basics, working with objects

## Select-Object (alias select)

The `Select-Object` cmdlet "filters" various properties from being returned to the PowerShell pipeline. To "filter” object properties from being returned, you can use the Property parameter and specify a comma-delimited set of one or more properties to return.

```powershell
Command:
Get-LMPortalInfo | Select-Object -Property companyDisplayName,numberOfOpenAlerts,numberOfDevices

Output:
#companyDisplayName numberOfOpenAlerts numberOfDevices
#------------------ ------------------ ---------------
#lmstevenvillardi                   30              16
```

## Sort-Object (alias sort)

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

## Group-Object (alias group)

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

## Where-Object (alias ?)

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

## ForEach-Object (alias %)

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

## Format-Table (alias ft)

Sometimes when viewing data that has a bunch of properties its easier to list them out in a table view where you can see the properties that matter most in a consolidate table.

```powershell
Command: (using default list view)
Get-LMDevice -Id 83 | Select-Object id,name,displayname,hostGroupIds,preferredCollectorId

Output:
#id                   : 83
#name                 : 127.0.0.1
#displayName          : lmstevenvillardi-wincol02
#hostGroupIds         : 389,13,373,5
#preferredCollectorId : 9

Command: (using Format-Table)
Get-LMDevice -Id 83 | Select-Object id,name,displayname,hostGroupIds,preferredCollectorId | Format-Table

Output:
#id name      displayName               hostGroupIds preferredCollectorId
#-- ----      -----------               ------------ --------------------
#83 127.0.0.1 lmstevenvillardi-wincol02 389,13,373,5                    9
```

As you can see if you were looking at a bunch of objects you would quickly lose the ability to distinguish what's what when looking at everything in a list but if we use Format-Table we can make the output displayed much easier to read.

**Important Note:** You should only use Format-Table for viewing data written to console output, you should not use Format-Table when storing an object as a variable as you will lose the ability to interact whith it in its orginaly format

**Table of Contents:**\
[Part 1: Intro to PowerShell](readme.md)\
[Part 2: LogicMonitor PowerShell Module Example Uses](LogicMonitorPS-Examples.md)\
[Part 3: LogicMonitor POV Prepper Utility](POV-Prepper-Utility.md)
