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

$EnumState = @{
        "Unknown" = 0
        "Running" = 1
        "Stopped" = 2
        "Start Pending" = 3
        "Stop Pending" = 4
        "Continue Pending" = 5
        "Pause Pending" = 6
        "Paused" = 7
        "Windows Server 2008" = 8
        "Windows Vista" = 9
}

$EnumStatus = @{
        "OK" = 1
        "Service" = 2
        "Degraded" = 3
        "Pred Fail" = 4
        "Lost Comm" = 5
        "No Contact" = 6
}

$EnumStartmode = @{
        "Disabled" = 0
        "Auto" = 1
        "Boot" = 2
        "Manual" = 3
        "System" = 4
}

$EnumErrorControl = @{
        "Unknown" = 0
        "Normal" = 1
        "Ignore" = 2
        "Severe" = 3
        "Critical" = 4
}

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
    Filter = "SELECT NAME, DISPLAYNAME, STATE, STATUS, STARTMODE, EXITCODE, STARTED, SERVICESPECIFICEXITCODE, ERRORCONTROL FROM Win32_Service WHERE NAME = `"$WildValue`""
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
        $Output = @()
        $Wildvalue = $Item.Name
        $Output = [PSCustomObject]@{
            '##WILDVALUE##' = $WildValue
            State = $EnumState[$Item.State]
            Status = $EnumStatus[$Item.Status]
            StartMode = $EnumStartmode[$Item.StartMode]
            ErrorControl = $EnumErrorControl[$Item.ErrorControl]
            ExitCode = $Item.ExitCode
            ServiceSpecificErrorCode = $Item.ServiceSpecificExitCode
            Started = If ($Item.Started) {1} Else {0}
        }
        
        $Output | ConvertTo-Json
    }
}
Exit 0