<# © 2007-2020 - LogicMonitor, Inc.  All rights reserved. #>

#######################      Active Discovery      #########################
# Purpose:
# Author:
#------------------------------------------------------------------------------------------------------------
# Prerequisites:
#
#
#Requires -Version 3
#------------------------------------------------------------------------------------------------------------
# Clears the CLI of any text
Clear-Host
# Clears memory of all previous variables
Remove-Variable * -ErrorAction SilentlyContinue
#------------------------------------------------------------------------------------------------------------
# Initialize Variables
$WinRmUser = '##WINRM.USER##'
$WinRmPass = '##WINRM.PASS##'
$Hostname = '##SYSTEM.HOSTNAME##'
$WinRMHttpPort = '##WINRM.HTTP.PORT##'
$WinRMHttpsPort = '##WINRM.HTTPS.PORT##'
$CollectorName = hostname

#Collect Auto Props set by Microsoft_PowerShell_WinRM_Info PS


$WinRMHTTPSEnabled = '##AUTO.WINRM.HTTPS.ENABLED##'
$WinRMHTTPEnabled = '##AUTO.WINRM.HTTP.ENABLED##'

#If WINRM.HTTP/HTTPS.PORT is set use that value otherwise fallback to what was detected during PS detection
If ([string]::IsNullOrWhiteSpace($WinRMHttpsPort) -or ($WinRMHttpsPort -like '*WINRM.HTTPS.PORT*')) {
    $WinRMHTTPSPort = '##AUTO.WINRM.HTTPS.PORT##'
}
If ([string]::IsNullOrWhiteSpace($WinRMHttpPort) -or ($WinRMHttpPort -like '*WINRM.HTTP.PORT*')) {
    $WinRMHTTPPort = '##AUTO.WINRM.HTTP.PORT##'
} 

# Resolve hostname IP/Name to FQDN for WinRM over https
$Hostname = [System.Net.Dns]::GetHostEntry($Hostname).Hostname

#Set parameters
$WSManParams = @{
    ErrorAction = 'SilentlyContinue'
    Filter = 'SELECT * FROM Win32_PerfRawData_PerfOS_Processor'
    ResourceURI = 'wmicimv2/*'
    Enumerate = $true
}

#-----Determine the type of query to make-----
# are WinRM user/pass props set -- e.g. are these device props either not substiuted or blank
If (([string]::IsNullOrWhiteSpace($WinRmUser) -and [string]::IsNullOrWhiteSpace($WinRmPass)) -or (($WinRmUser -like '*WINRM.USER*') -and ($WinRmPass -like '*WINRM.PASS*'))) {
    $WSManParams.ComputerName = $Hostname
} 
Else {
    # yes. convert user/password into a credential string
    $RemotePass = ConvertTo-SecureString -String $WinRmPass -AsPlainText -Force;
    $RemoteCredential = New-Object -typename System.Management.Automation.PSCredential -argumentlist $WinRmUser, $RemotePass;
    $WSManParams.ComputerName = $Hostname
    $WSManParams.Authentication = 'default'
    $WSManParams.Credential = $RemoteCredential
}

#Get configured WinRM HTTPS Port if configured
If($WinRMHTTPSEnabled -eq $true){
    $WSManParams.Port = $WinRMHttpsPort
    $WSManParams.UseSSL = $true
}
#Get configured WinRM HTTPS Port if configured
ElseIf($WinRMHTTPEnabled -eq $true){
    $WSManParams.Port = $WinRMHttpPort
    $WSManParams.UseSSL = $false
}
#WinRM not detected as being configured, quit processing any further
Else{
    Write-Host "WinRM is not detected as being enabled, please ensure winRM is configured and try again"
    Exit 1
}

#Attempt to get WMI results over WinRM
$Result = Get-WSManInstance @WSManParams
If($Result){
    Foreach($Item in $Result){
        $Wildvalue = $Item.Name -replace '[:|\\|\s|=|#]+','_'
        Write-Host "$Wildvalue.PercentProcessorTime=$($Item.PercentProcessorTime)"
    }
}
Exit 0