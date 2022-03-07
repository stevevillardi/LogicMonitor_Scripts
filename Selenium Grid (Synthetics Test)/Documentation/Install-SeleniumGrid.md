## Install-SeleniumGrid.ps1

This script is designed to automate all of the manual steps required to get Selenium GRID installed and ready to run alongside LogicMonitor on a Windows VM/Host

Steps automated through PowerShell script:

- Downloads and silently installs the latest version of Java 8

- Downloads and silently installs the latest version of Chrome

- Downloads the latest matching version of the chromedriver based on the installed version

- Creates working directory for all Selenium configuration requirements

- Disables AutoUpdates for Chrome to allow for manual updates and more control over when to upgrade chrome and chromedriver

- Creates a batch script to start up selenium GRID in standalone mode

- Creates a Windows scheduled task that starts up selenium whenever the server is restarted (runs as LOCAL SYSTEM by default, can be modified once created)

## Parameters

- **DefaultDirectory:** File path for all Selenium requirement, defaults to "C:\LogicMonitor-Selenium" if not specified. Will create directory if it does not exist.

- **ScheduleTaskName:** Name to use when creating windows schedule task. Defaults to "LogicMonitor-Selenium GRID 4 Startup".

- **DisableChromeAutoUpdates:** Set optional registry key to disable AutoUpdates. This is only setting enforced by chrome if set on a domain joined machine. Defaults to "true".

- **SeleniumPort:** Port to use to run Selenium GRID on. Defaults to 4444 if not specified.

- **SeleniumMaxSessions:** The max number of sessions to allowed for a given browser. Defaults to 4 if not specified. Selenium will set this value to the number of cores available to the host if a larger number is specified than the number of cores available.

### Examples:

```powershell
#Run with all defaults
./Install-SeleniumGrid.ps1

#Specify default directory and selenium port/session options
./Install-SeleniumGrid.ps1 -DefaultDirectory "C:\SeleniumGRID" -SeleniumPort 1234 -SeleniumMaxSessions 2

#Specify Task name and do not disable chrome AutoUpdates
./Install-SeleniumGrid.ps1 -DisableChromeAutoUpdates $false -ScheduleTaskName "Selenium-Startup-Script"
```
