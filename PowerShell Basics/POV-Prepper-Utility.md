# Part 3: LogicMonitor POV Prepper Utility

Now that have an understanding of working with the LM PowerShell module and some ways to interact with PS objects, we can turn to looking at some of the utilities included with the PS module.

## POV Prepper Utility

When starting a new POV there is often a checklist of items that need to be done on everyone. Since these steps often are the same amongst POVs it makes sense to try and automate the process as much as possible. The Initialize-LMPOVSetup command is used to do just that. Below is a list of options you have when running the utility and what is actually done behind the scenes:

- **SetupWebsite:** Creates a External Webcheck using the _Website Default_ settings for any website specific using the parameter **Website**

- **SetupPortalMetrics:** Generates an API user and token for use with portal metrics, creates a LogicMonitor Portal Metrics dynamic group, creates a customer.logicmonitor.com device and assigns the appropriate properties.

- **MoveMinimalMonitoring:** Moves the _Minimal Monitoring_ folder into _Devices by Type_. Also modifies the AppliesTo query to exclude Meraki and PortalMetrics devices from showing up.

- **CleanUpDynamicGroups:** Deletes the Misc folder and updates the Linux Servers folders AppliesTo to include Linux_SSH devices

- **RunAll:** Performs all of the above functions

##### Parameters

**-Website** : The name of the website to use for webcheck creation (example.com)
**-WebstieHttpType** : Protocol to use for webcheck (http or https). Defaults to **https** if not specified
**-APIUsername** : The name to use for creation of the API User. Defaults to **lm_api** if not specified.

This utility is an ongoing devlopment. If you have things you would like added to this prep utility let me know (customer image upload, upload additonal datasources/dashboards, etc)

**Notes:** This utility should be ran after the customer has deployed their first collector so we can corectly provision the portal metrics resource

**Table of Contents:**\
[Part 1: Intro to PowerShell](readme.md)\
[Part 2: LogicMonitor PowerShell Module Example Uses](LogicMonitorPS-Examples.md)\
[Part 3: LogicMonitor POV Prepper Utility](POV-Prepper-Utility.md)
