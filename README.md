# LogicMonitor_Scripts
Collection of LM Scripts created to aid leveraging LogicMonitor

### Get LMCloud resource count estimate from Azure
- Script: Get-LMCloudAzureResourceCount.ps1

- Usage:
```powershell
#Only discover resources in the salesdemo and development resource groups
 ./Get-LMCloudAzureResourceCount -includeResourceGroups salesdemo,development

#Discover everthing is except the salesdemo and development resource groups
./Get-LMCloudAzureResourceCount -excludeResourceGroups salesdemo,development
```

- Outputs:
Exports a CSV file to current working directory with list of resources.

### Install pre-requsites for Selenium scripting on Windows Collector
- Script: Install-Selenium.ps1

- Usage:
```powershell
#Checks for and installs Chrome, Chromdriver and Selenium. Adds the selenium jar to the collector wrapper.conf file if not present and restarts the collector if not.
 ./Install-Selenium.ps1
```

- Outputs:
None.