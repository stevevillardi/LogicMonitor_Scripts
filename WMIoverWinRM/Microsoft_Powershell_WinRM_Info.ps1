<# © 2007-2020 - LogicMonitor, Inc.  All rights reserved. #>

#######################      PropertySource      #########################
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

#Default properties
$WinRMEnabled = $false
$WinRMHTTPEnabled = $false
$WinRMHTTPSEnabled = $false

# Resolve hostname IP/Name to FQDN for WinRM over https
$Hostname = [System.Net.Dns]::GetHostEntry($Hostname).Hostname

#Set parameters
$WSManParams = @{
    ErrorAction = 'SilentlyContinue'
    ComputerName = $Hostname
}

#Check if custom ports are defined and if not use defaults
If ([string]::IsNullOrWhiteSpace($WinRMHttpsPort) -or ($WinRMHttpsPort -like '*WINRM.HTTPS.PORT*')) {
    $WinRMHttpsPort = 5986
} 
If ([string]::IsNullOrWhiteSpace($WinRMHttpPort) -or ($WinRMHttpPort -like '*WINRM.HTTP.PORT*')) {
    $WinRMHttpPort = 5985
}

#Test if any WinRM ports are open
$WinRmHttp = Test-NetConnection -ComputerName $Hostname -Port $WinRMHttpPort -InformationLevel Quiet -WarningAction SilentlyContinue
$WinRmHttps = Test-NetConnection -ComputerName $Hostname -Port $WinRMHttpsPort -InformationLevel Quiet -WarningAction SilentlyContinue

#-----Determine the type of query to make-----
# are WinRM user/pass set -- e.g. are these device props either not substiuted or blank
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

#Test WinRM over HTTPS
If($WinRmHttps){
    $WSManParams.UseSSL = $true
    $WSManParams.Port = $WinRMHttpsPort

    If(Test-WSMan @WSManParams){
        $WinRMEnabled = $true
        $WinRMHTTPSEnabled = $true
        Write-Host "auto.winrm.https.port=$WinRMHttpsPort"
    }  
}

#Test WinRM over HTTP
If($WinRmHttp){
    $WSManParams.UseSSL = $false
    $WSManParams.Port = $WinRMHttpPort

    If(Test-WSMan @WSManParams){
        $WinRMEnabled = $true
        $WinRMHTTPEnabled = $true
        Write-Host "auto.winrm.http.port=$WinRMHttpPort"
    }
}

Write-Host "auto.winrm.http.enabled=$WinRMHTTPEnabled"
Write-Host "auto.winrm.https.enabled=$WinRMHTTPSEnabled"
Write-Host "auto.winrm.enabled=$WinRMEnabled"
Exit 0