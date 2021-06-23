#Requires -RunAsAdministrator

#Make sure collector is installed before proceeding
$CollectorPath = (Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_.DisplayName -eq "LogicMonitor Collector" }).InstallLocation
If (!$CollectorPath) {
    Write-Host "[INFO]:LogicMonitor collector not detected, ensure a collector is running on this host"
    #return
}
Else {
    Write-Host "[INFO]:LogicMonitor collector agent detected at install path :$CollectorPath"
}

#Install latest version of chrome
$ChromeTest = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue
If (!$ChromeTest) {
    Write-Host "[INFO]:Downloading Chrome"
    $Installer = "chrome_installer.exe"
    Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Installer
    Write-Host "[INFO]:Running silent install of Chrome"
    Start-Process -FilePath $Installer -Args "/silent /install" -Verb RunAs -Wait
    Remove-Item $Installer -Confirm:$false
    $ChromePath = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').Path
    $ChromeVersion = ((Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo).ProductVersion
}
Else {
    $ChromeVersion = ((Get-Item $ChromeTest.'(Default)').VersionInfo).ProductVersion
    $ChromePath = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').Path
    Write-Host "[INFO]:Previous version of Google Chrome already detected: $($ChromeVersion). Skipping Chrome install"
}

#Install latest ChromeDriver.
If (!$(Test-Path -Path "$ChromePath\chromedriver.exe")) {
    Write-Host "[INFO]:Downloading Chromedriver for Selenium"
    $ChromeDriverVersion = Invoke-RestMethod -Method Get -Uri "https://chromedriver.storage.googleapis.com/LATEST_RELEASE"
    $ChromeDriverZip = "chromedriver_win32.zip"
    Invoke-RestMethod -Method get -Uri "https://chromedriver.storage.googleapis.com/$ChromeDriverVersion/chromedriver_win32.zip" -OutFile $ChromeDriverZip
    Expand-Archive -Path $ChromeDriverZip -Force
    Remove-Item -Path $ChromeDriverZip -Confirm:$false
    If ($(Test-Path -Path $ChromePath)) {
        Write-Host "[INFO]:Moving Chromedriver into chrome install directory"
        Move-Item -Path "chromedriver_win32\chromedriver.exe" -Destination $ChromePath -Force
        Remove-Item -Path "chromedriver_win32" -Confirm:$false -Force
    }
    Else {
        Write-Host "[INFO]:Chrome directory not detected, unable to move chromedriver into correct location"
    }
}
Else {
    Write-Host "[INFO]:Skipping Chromedrive install since a version is already been detected at: $ChromePath"
}

#Instal Selenium
If (!$(Test-Path -Path "$CollectorPath\custom\selenium-server-standalone-3.141.59.jar")) {
    Write-Host "[INFO]:Downloading Selenium Jar file"
    $SeleniumJar = "selenium-server-standalone-3.141.59.jar"
    Invoke-RestMethod -Method Get -Uri "https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar" -OutFile $SeleniumJar
    #Check for LogicMonitor directory
    If ($(Test-Path -Path $CollectorPath) -and !$(Test-Path -Path "$CollectorPath/custom" )) {
        Write-Host "[INFO]:Creating custom jar folder in LogicMonitor agent directory"
        New-Item -ItemType "Directory" -Path $CollectorPath -Name "custom" | Out-Null
    }
    Move-Item -Path $SeleniumJar -Destination "$CollectorPath/custom" -Force
}
Else {
    Write-Host "[INFO]:Skipping selenium JAR download since a version is already been detected at: C:\Program Files (x86)\LogicMonitor\Agent\custom\selenium-server-standalone-3.141.59.jar"
}

If (Get-Content "C:\Program Files (x86)\LogicMonitor\Agent\conf\wrapper.conf" | Select-String -SimpleMatch "selenium") {
    Write-Host "[INFO]:Selenium already added to configuration, skipping wrapper modificaiton"
}
Else {
    Write-Host "[INFO]:Adding selenium jar to collector wrapper configuration"
    #Get total number of jars already loaded
    [int]$TotalJars = (Get-Content -Path "C:\Program Files (x86)\LogicMonitor\Agent\conf\wrapper.conf" | Select-String -Pattern "wrapper.java.classpath.[0-9]+=../" | Measure-Object -Line).Lines
    [int]$NewJar = $TotalJars + 1

    #Get current conf line for last wrapper entry
    [int]$CurrentJarLine = (Get-Content -Path "C:\Program Files (x86)\LogicMonitor\Agent\conf\wrapper.conf" | Select-String -Pattern "wrapper.java.classpath.*=." | Select-Object -Last 1 LineNumber, Line).LineNumber
    [int]$NewJarLine = $CurrentJarLine #Dont need to increase by one since array index starts at 0

    $WrapperConf = Get-Content -Path "C:\Program Files (x86)\LogicMonitor\Agent\conf\wrapper.conf"
    If (!$WrapperConf[$NewJarLine]) {
        #Only append if new line is empty
        Write-Host "[INFO]:Adding jar export to wrapper config on line $NewJarLine"
        $WrapperConf[$NewJarLine] = "wrapper.java.classpath.$NewJar=../custom/selenium-server-standalone-3.141.59.jar"
        Set-Content -Path "C:\Program Files (x86)\LogicMonitor\Agent\conf\wrapper.conf" -Value $WrapperConf

        #Restart collector to have new config take effect
        Write-Host "[INFO]:Restarting LogicMonitor Agent for changes to take effect"
        Restart-Service -Name logicmonitor-agent
    }
    Else {
        Write-Host "[INFO]: Unable to add the selenium jar export entry to the wrapper.conf file, manually add the entry to your collector confgiuration after this script completes and restart the logicmonitor service."
    }

}

Write-Host "Selenium Configuration Complete"
Write-Host "    Google Chrome Version: $ChromeVersion" -ForegroundColor Green
Write-Host "    Chromedriver File Path: $ChromePath\chromedriver.exe" -ForegroundColor Green
Write-Host "    Selenium JAR File Path: $CollectorPath\selenium-server-standalone-3.141.59.jar" -ForegroundColor Green
