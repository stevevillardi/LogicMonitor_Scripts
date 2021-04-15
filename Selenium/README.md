# Selenium Installation and Configuration (Using Chrome)

### Step 1: Ensure you have a windows/linux collector to run Selenium on

### Step 2: Follow the setup instructions for Windows or Linux depending on your collector OS:

#### Step 2a: Windows Collector Setup (Automatic)

Run the following commands from an administrative PowerShell session to automatically prepare your collector to run Selenium:

```powershell
#Download and run directly from PS session
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/stevevillardi/LogicMonitor_Scripts/main/Selenium/Install-Selenium.ps1" | Invoke-Expression
```

#### Step 2a: Linux Collector Setup (Automatic)

Run the following commands from a Linux to automatically prepare your collector to run Selenium:

```bash
#Download and run directly from ssh/console session
curl -L "https://raw.githubusercontent.com/stevevillardi/LogicMonitor_Scripts/main/Selenium/logicmonitor_install_selenium_debian.sh" | sh
```

#### Step 2b: Manual Collector Setup (Windows and Linux)

Run through the following steps to manually prepare your collector to run Selenium, skip this step if using automatic configuration scripts:

1.  Download and install the latest version of Google Chrome : https://www.google.com/chrome/
2.  Download the latest stable release of the ChromeDriver for your installed version of Google Chrome: https://chromedriver.chromium.org/downloads
    - Extract the `chromdriver` executable and place into the Google Chrome install directory (ex. C:\Program Files\Google\Chrome\Application | /usr/bin/)
3.  Download the latest release of Selenium Server: https://www.selenium.dev/downloads/
    - Create a `custom` folder inside of the LogicMonitor Agent install directory if it does not already exist (ex. C:\Program Files (x86)\LogicMonitor\Agent\custom | /usr/local/logicmonitor/agent/custom)
    - Copy the downloaded `selenium-server-standalone-xxx.jar` file into the custom directory
4.  From the `LM_Install_Path/Agent/conf` directory, edit the wrapper.conf file:
    - Find the last line entry for `wrapper.java.classpath.###=` and create a new line incrementing the number by 1 and pointing to our custom selenium jar file similar to below:
      `wrapper.java.classpath.135=../custom/selenium-server-standalone-3.141.59.jar`
5.  Save and close the wrapper.conf file and restart the LM collector service for it take effect

### Step 3: Install the Selenium IDE for Chrome

1. Install and activate the chrome extension from the chrome web store: https://chrome.google.com/webstore/detail/selenium-ide/mooikfkahbdckldjjndioackbalphokd?hl=en

### Step 4: Record new Selenium IDE Project

1. Click on Selenium extension in Chrome
2. Click on `Record a new test in a new project`
3. Name your project
4. Set the base url for your synthetic test
5. Record your test and click on `stop recording` once completed, give your test a name
6. Optionally add in some assert statements or other non recorded steps required for testing
7. Replay your test from the IDE window and verify it operates as expected, make any adjustments/cleanup needed until satisfied

### Step 5: Export Selenium Project to Java

1. Right-click on your test and choose `Export` and choose `Java JUnit` as the export type
2. Click export and save your java file to your machine

### Step 6: Import Selenium Datasource Template

1. Grab the selenium datasource template from GitHub:
   - https://github.com/stevevillardi/LogicMonitor_Scripts/blob/main/Selenium_Template.xml
2. Import the Selenium_Template.xml into LM portal
3. Open the Selenium Recording Java file and copy the content starting with driver.get("url") to the end of the function and paste it into the try block in the datasource groovy script area
4. Modify the groovy script with any properties needed and steps you are testing for.
5. Modify the appliesTo criteria so it applies to the appropriate device and test the script until it works as expected
6. Optionally alter any graph definitions/datapoints as needed

#### Supporting articles:

- Adding additional libraries to the LM Collector: https://www.logicmonitor.com/support/terminology-syntax/scripting-support/adding-groovy-libraries
- Using asserts in groovy: http://grails.asia/groovy-assert-examples
