#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Install')]
param (
    [Parameter(ParameterSetName = 'Install')]
    [Parameter(ParameterSetName = 'Upgrade')]
    [String]$DefaultDirectory = "C:\LogicMonitor-Selenium", #Default file path for all things Selnium

    [Parameter(ParameterSetName = 'Install')]
    [String]$ScheduleTaskName = "LogicMonitor-Selenium GRID 4 Startup", #Name used to create scheduled task.

    [Parameter(ParameterSetName = 'Install')]
    [Boolean]$DisableChromeAutoUpdates = $true, #Adds registry file to disable chrome upates, allows for manual control over updates as the installed chromedriver must match the installed chrome version for slenium to work.

    [Parameter(ParameterSetName = 'Install')]
    [Int]$SeleniumPort = 4444, #Default port for selenium grid hub

    [Parameter(ParameterSetName = 'Install')]
    [Int]$SeleniumMaxSessions = 4, #Default maximum number of sessions, will default to the number of cores if set size is larger then available core count.

    [Parameter(ParameterSetName = 'Upgrade')]
    [Switch]$UpgradeChromeDriver #For exisitng installs, this will simply check the installed chrome version and ensure it matches the chrome driver installed. Ensure you set the appropriate DefaultDirectory is using a custom location
    )
#Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

If($UpgradeChromeDriver){
    If(!(Test-Path $DefaultDirectory)){
        Write-Error "Unable to locate default directory: $DefaultDirectory, ensure you have the DefaultDirectory parameter set if using a customer directory"
        return
    }
    Else{
        #Get Chrome driver version and Chrome version and check if an update is needed
        $ChromeTest = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue
        If (!$ChromeTest) {
            Write-Error "Unable to locate Chrome on this machine unable to validate chrome driver, ensure Chrome is installed on this machine before proceeding"
            return
        }
        Else{
            $ChromeVersion = ((Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo).ProductVersion
            $ChromeDriverVersion = [regex]::Match("$(.$DefaultDirectory\chromedriver.exe -v)",'(\d{1,}.\d{1,}.\d{1,}.\d{1,})').Value
            If(!$ChromeDriverVersion){
                Write-Error "Unable to determine the Chromedriver version installed."
                return
            }
            Else{
                [int]$ChromeMajorVersion = [System.Version]::Parse($ChromeVersion).Major
                [int]$ChromeDriverMajorVersion = [System.Version]::Parse($ChromeDriverVersion).Major
                If($ChromeMajorVersion -ne $ChromeDriverMajorVersion){
                    Write-Host "[INFO]: Detected Chromedriver($ChromeDriverVersion) is out of date for version of Chrome($ChromeVersion) currently installed, downloading Chromedriver for Selenium"
                    $ChromeDriverUpgradeVersion = Invoke-RestMethod -Method Get -Uri "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$ChromeMajorVersion"
                    $ChromeDriverZip = "$DefaultDirectory\chromedriver_win32.zip"
                    Invoke-RestMethod -Method get -Uri "https://chromedriver.storage.googleapis.com/$ChromeDriverUpgradeVersion/chromedriver_win32.zip" -OutFile $ChromeDriverZip
                    Rename-Item -Path "$DefaultDirectory\chromedriver.exe" -NewName "old_chromedriver.exe" -Confirm:$false -Force
                    Expand-Archive -Path $ChromeDriverZip -Force
                    Remove-Item -Path $ChromeDriverZip -Confirm:$false
                    If ($(Test-Path -Path $DefaultDirectory)) {
                        Write-Host "[INFO]: Moving Chromedriver into default directory"
                        Move-Item -Path "chromedriver_win32\chromedriver.exe" -Destination $DefaultDirectory -Force
                        Remove-Item -Path "chromedriver_win32" -Confirm:$false -Force
                        Remove-Item -Path "$DefaultDirectory\old_chromedriver.exe" -Confirm:$false -Force
                        Write-Host "[INFO]: Chromedriver successfully upgraded"
                    }
                    Else {
                        Write-Host "[INFO]: Chrome directory not detected, unable to move chromedriver into correct location"
                        Return
                    }
                }
                Else{
                    Write-Host "Currently installed Chrome($ChromeVersion) and Chromedriver($ChromeDriverVersion) are at matching major version levels, skipping upgrade"
                    Return
                }
            }
        }
    }
}
Else{
    If(!(Test-Path $DefaultDirectory)){
        Write-Host "[INFO]: Default directory not found, creating directory: $DefaultDirectory"
        $NewDefaultDirectory = New-Item -ItemType Directory -Name "LogicMonitor-Selenium" -Path "C:\"
    
        If(!$NewDefaultDirectory){
            Write-Error "Unable to create default directory: $DefaultDirectory"
            Return
        }
    }
    Else{
        Write-Host "[INFO]: Default directory found, using directory ($DefaultDirectory) for configuration of Selenium GRID"
    }
    
    #Test if Java is currently installed
    $JavaVersionInstalled = Get-ChildItem "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty pschildname -Last 1
    If(!$JavaVersionInstalled){
        #Download folder for Java installer
        $JavaDownloadsDirectory = "$DefaultDirectory\64bit-java.exe"
        
        If(Test-Path -Path $DefaultDirectory){
            #Continue with java installation
            Try {
                Write-Host "[INFO]: Java not detected, downloading latest version of Java..."
                #Lastest URL for 64-bit Windows
                $JavaURL = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=245060_d3c52aa6bfa54d3ca74e617f18309292" 
                Invoke-WebRequest -Uri $JavaURL -OutFile $JavaDownloadsDirectory
                Write-Host "[INFO]: Installing latest version of Java..."
                $JavaProcess = Start-Process -FilePath $JavaDownloadsDirectory -ArgumentList "/s REBOOT=ReallySuppress" -Wait -PassThru
                $JavaProcess.waitForExit()
                $JavaVersionInstalled = (Get-Command java -ErrorAction SilentlyContinue).Version -join (".")
                Remove-Item $JavaDownloadsDirectory -Confirm:$false
                Write-Host "[INFO]: Latest version of Java has been successfully installed."
            } 
            Catch [Exception] {
                Write-Error $_.Exception.Message
                Return
            }
        }
        Else{
            Write-Error "[ERROR]: Unable to download Java installer, please manually install java to continue"
            Return
        }
    }
    Else {
        Write-Host "[INFO]: Java version $JavaVersionInstalled is already installed, skipping install process."
    }
    
    #Test is Chrome is installed and if not download and install
    $ChromeTest = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue
    If (!$ChromeTest) {
        Write-Host "[INFO]: Downloading Chrome"
        $Installer = "$DefaultDirectory\chrome_installer.exe"
        Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Installer
        Write-Host "[INFO]: Running silent install of Chrome"
        Start-Process -FilePath $Installer -Args "/silent /install" -Verb RunAs -Wait
        Remove-Item $Installer -Confirm:$false
        $ChromePath = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').Path
        $ChromeVersion = ((Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo).ProductVersion
        Write-Host "[INFO]: Latest version of Chrome($ChromeVersion) has been successfully installed."
    }
    Else {
        $ChromeVersion = ((Get-Item $ChromeTest.'(Default)').VersionInfo).ProductVersion
        $ChromePath = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').Path
        Write-Host "[INFO]: Previous version of Google Chrome already detected: $($ChromeVersion). Skipping Chrome install"
    }
    
    #Disable Chrome updates to stop chromedriver version missmatch
    $DisableUpdatesKey = (Get-ItemProperty -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Update" -ErrorAction SilentlyContinue).AutoUpdateCheckPeriodMinutes
    If(!$DisableUpdatesKey -and $DisableChromeAutoUpdates){
        Write-Host "[INFO]: Setting registry key to disabled Chrome auto updates"
        [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Update", "AutoUpdateCheckPeriodMinutes", 0)
    }
    
    #Install latest ChromeDriver.
    If (!$(Test-Path -Path "$DefaultDirectory\chromedriver.exe")) {
        Write-Host "[INFO]: Downloading Chromedriver for Selenium"
        #Was chrome already installed, if so need to make sure we download the matching version
        If($ChromeTest){
            $ChromeMajorVersion = [System.Version]::Parse($ChromeVersion).Major
            $ChromeDriverVersion = Invoke-RestMethod -Method Get -Uri "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$ChromeMajorVersion"
        }
        Else{
            $ChromeDriverVersion = Invoke-RestMethod -Method Get -Uri "https://chromedriver.storage.googleapis.com/LATEST_RELEASE"
            
        }
        $ChromeDriverZip = "$DefaultDirectory\chromedriver_win32.zip"
        Invoke-RestMethod -Method get -Uri "https://chromedriver.storage.googleapis.com/$ChromeDriverVersion/chromedriver_win32.zip" -OutFile $ChromeDriverZip
        Expand-Archive -Path $ChromeDriverZip -Force
        Remove-Item -Path $ChromeDriverZip -Confirm:$false
        If ($(Test-Path -Path $DefaultDirectory)) {
            Write-Host "[INFO]: Moving Chromedriver into default directory"
            Move-Item -Path "chromedriver_win32\chromedriver.exe" -Destination $DefaultDirectory -Force
            Remove-Item -Path "chromedriver_win32" -Confirm:$false -Force
        }
        Else {
            Write-Host "[INFO]: Chrome directory not detected, unable to move chromedriver into correct location"
            Return
        }
    }
    Else {
        Write-Host "[INFO]: Skipping Chromedrive install since a version is already been detected at: $DefaultDirectory"
    }
    
    #URL for seleniumGrid, need to figure out way to grab latest version automatically
    $SeleniumGridURL = "https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.1.0/selenium-server-4.1.1.jar"
    $SeleniumJarFile = $SeleniumGridURL.Split("/")[-1]
    If(!(Test-Path "$DefaultDirectory\$SeleniumJarFile")){
        Write-Host "[INFO]: Selenium grid not detected, downloading version $([System.IO.Path]::GetFileNameWithoutExtension($SeleniumJarFile))"
        Invoke-WebRequest -Uri $SeleniumGridURL -OutFile "$DefaultDirectory\$SeleniumJarFile"
    }
    Else{
        Write-Host "[INFO]: Selenium grid already detected, skipping download"
    }
    
    #Create Startup script and scheduled task
    $BatchScriptContent = "cmd /c start /min java -Dwebdriver.chrome.driver=./chromedriver.exe -jar $SeleniumJarFile standalone --port $SeleniumPort --max-sessions $SeleniumMaxSessions"
    $BatchScriptFile = Set-Content "$DefaultDirectory\selenium-startup.bat" $BatchScriptContent -Encoding ASCII
    $ExistingScheduledTask = Get-ScheduledTask -TaskPath \ -TaskName $ScheduleTaskName -ErrorAction SilentlyContinue
    If(!$ExistingScheduledTask){
        Try{
            $Trigger = New-ScheduledTaskTrigger -AtStartup
            $Action = New-ScheduledTaskAction -Execute "$DefaultDirectory\selenium-startup.bat" -WorkingDirectory $DefaultDirectory
            $Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $Task = New-ScheduledTask -Action $Action -Description "Startup Script for Selenium Grid 4" -Trigger $Trigger -Principal $Principal
            $ScheduledTask = Register-ScheduledTask -InputObject $Task -TaskName $ScheduleTaskName
            If($ScheduledTask){
                Write-Host "[INFO]: Successfully registered scheduled task for Selenium startup"
            }
            Else{
                Write-Error "[ERROR]: Unable to create schedule task for automated startup: "
            }
        }
        Catch [Exception] {
            Write-Error $_.Exception.Message
            Return
        }
        #Run scheduled task so selenium is running
        $StartScheduledTask = Start-ScheduledTask -TaskName $ScheduleTaskName
        Write-Host "[INFO]: Successfully started scheduled task"
        $HostAddress = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -ErrorAction SilentlyContinue | Where-Object {$_.InterfaceAlias -notlike "*loopback*"}).IPAddress
        If($HostAddress){
            Write-Host "[INFO]: Selenium GRID started under LOCAL SYSTEM account, verify status using URL: http://$HostAddress`:4444"
        }
        Else{
            Write-Host "[INFO]: Selenium GRID started under LOCAL SYSTEM account, verify status using URL: http://localhost:4444"
            Write-Host "[INFO]: Selenium is running under a scheduled task therefore it is recommended to run selenium in headless mode so commands such as 'set window size', function as expected."
        }
    
    }
    Else {
        Write-Host "[INFO]: Existing scheduled task ($ScheduleTaskName) already exists, skipping creation"
    }
}
