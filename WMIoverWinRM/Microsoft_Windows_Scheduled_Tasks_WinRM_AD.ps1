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
$SessionParams = @{
    ErrorAction = 'SilentlyContinue'
}

$ScripBlock = {
    $ResultSet = @()
    $Index = 0
    $Task = Get-ScheduledTask
    $TaskInfo = $Task | Get-ScheduledTaskInfo
    Foreach($Item in $Task){
        $ResultSet += [PSCustomObject]@{
            TaskName = $TaskInfo[$Index].TaskName
            TaskPath = $TaskInfo[$Index].TaskPath
            TaskState = $Item.State
        }
        $Index++
    }

    $ResultSet
}

#-----Determine the type of query to make-----
# are WinRM user/pass props set -- e.g. are these device props either not substiuted or blank
If (([string]::IsNullOrWhiteSpace($WinRmUser) -and [string]::IsNullOrWhiteSpace($WinRmPass)) -or (($WinRmUser -like '*WINRM.USER*') -and ($WinRmPass -like '*WINRM.PASS*'))) {
    $SessionParams.ComputerName = $Hostname
} 
Else {
    # yes. convert user/password into a credential string
    $RemotePass = ConvertTo-SecureString -String $WinRmPass -AsPlainText -Force;
    $RemoteCredential = New-Object -typename System.Management.Automation.PSCredential -argumentlist $WinRmUser, $RemotePass;
    $SessionParams.ComputerName = $Hostname
    $SessionParams.Authentication = 'default'
    $SessionParams.Credential = $RemoteCredential
}

#Get configured WinRM HTTPS Port if configured
If($WinRMHTTPSEnabled -eq $true){
    $SessionParams.Port = $WinRMHttpsPort
    $SessionParams.UseSSL = $true
}
#Get configured WinRM HTTPS Port if configured
ElseIf($WinRMHTTPEnabled -eq $true){
    $SessionParams.Port = $WinRMHttpPort
    $SessionParams.UseSSL = $false
}
#WinRM not detected as being configured, quit processing any further
Else{
    Write-Host "WinRM is not detected as being enabled, please ensure winRM is configured and try again"
    Exit 1
}

#Attempt to get WMI results over WinRM
$Session = New-PSSession @SessionParams
If($Session){
    $Result = Invoke-Command -Session $Session -ScriptBlock $ScripBlock
    If($Result){
        Foreach($Item in $Result){
            $Wildvalue = $Item.TaskName -replace '[:|\\|\s|=|#]+','_'
            Write-Host "$Wildvalue##$($Item.TaskName)######auto.scheduled.task.name=$($Item.TaskName)&auto.scheduled.task.path=$($Item.TaskPath)&auto.scheduled.task.state=$($Item.TaskState)"
        }
        Get-PSSession | Remove-PSSession
    }
    Exit 0
}
Else{
    Write-Host "Unable to establish remote connection"
    return 1
}