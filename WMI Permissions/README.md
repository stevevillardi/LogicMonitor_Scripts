# WMI Permissions

Steps to setup WMI access via GPO/Manually using least privledge permissions

# First – Setting done from Active Directory

Open the Active Directory Administrative Center:

- Go to Contoso -> Users
- Right click and select New -> User
- Create user as a normal user and ways **User UPN logon** to **wmiuser@contoso.local**
- Make sure Member of is set to Domain Users so that the user is in a valid group.

## 1 – Create the Group Policy Object

Open the Group Policy Management:

- Create a new GPO and name it **WMI Access**
- Link it to contoso.local domain (drag and drop the it on contoso.local)
- Make sure that the GPO will be applied to all machines in the domain to be monitored (WMI adjust Security Filtering, etc.)

## 2 – Settings GPO

### Perfomance Monitor Users, Event Log Readers Groups and Distributed COM Users

- Right-click **WMI Access** (which is the GPO we just created), select Edit
- Go to Computer **Configuration -> Preferences -> Control Panel Settings -> Local Users and Groups**
- Right-click **Local Users and Groups**, select **New** -> **Local Group**
- Leave Action dropdown to **Update** and select **Performance Monitor Users (built-in)** from the Group Name dropdown
- Click **Add**
- Click the three **...** to open the search box and enter **wmiuser** and check name to ensure a valid user is specified
- Click **OK**
- Make sure the Action is set to **Add to this group**
- Click **OK**
- Click **OK**
- Repeat these steps for the **Event Log Readers (built-in) and Distributed COM Users (built-in)** local groups

### Firewall

- Right-click **WMI Access** (the GPO we just created), select **Edit**
- Go to **Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Windows Firewall with Advanced Security**
- In the right pane, expand **Windows Firewall with Advanced Security** until **Inbound Rules** visible. Right-click on it
- Choose **New Rule …**
- Select **Predefined** and **Windows Management Instrumentation (WMI)** in the list
- Click **Next**
- Tick all the **Windows Management Instrumentation-rules** in the list (usually 3 pieces)
- Click **Next**
- Select **Allow The Connection**
- Click **Finish**

### WMI Namespace Permissions (Auto and Manual)

These settings can not be done with a regular GPO. _For a user who is not Admin this step is critical and must be done exactly as instructed below_. If not properly done, login attempts via WMI results in Access Denied.

- ### GPO Startup Script - Automatic

    To set these settings via GPO you can use the following PS script (https://github.com/stevevillardi/LogicMonitor_Scripts/blob/main/WMI%20Permissions/Set-WmiNamespaceSecurity.ps1) as a startup script GPO task:

    - Right-click **WMI Access** (the GPO we just created), select **Edit**
    - Go to **Computer Configuration -> Policies -> Windows Settings -> Scripts**
    - In the right pane, click on Startup. Right click on it
    - Choose **Properties**
    - Click **Add**
    - Click **Browse**, navigate to the script **Set-WmiNamesapceSecurity.ps1**
    - Enter the following script parameters (replace **wmiuser** with your username):

    ```powershell
    Set-WmiNamespaceSecurity root/cimv2 add wmiuser MethodExecute,Enable,RemoteAccess,ReadSecurity
    ```

    - Click **Ok** x2

    ### Individual Server - Manually

    To perform these steps manually on a server to be monitored via LogicMonitor, perform the following steps:

    - Write **wmimgmt.msc** in command prompt
    - Right-click **WMI Control**, and select **Properties**
    - Select the **Security** tab
    - Select **Root** of the tree and click on **Security**
    - Click **Add …**
    - Under **Enter the object names to select:** Enter**wmiuser** and click **Check Names**. The user is now filled in automatically
    - Click **OK**
    - Select **wmiuser (wmiuser@contoso.local)**
    - Select **Allow**for**Execute Methods, Enable Account, Remote Enable and Read Security** under **Permissions** for wmiuser
    - Mark wmiuser and click **Advanced**
    - Under the Permission tab: Select **wmiuser**
    - Click **Edit**
    - Under **Applies To-**list: Choose **This namespace and all subnamespaces**. _It is very important that the rights are applied recursively down the entire tree!_
    - Click **OK** x4

# Second – Settings done on each machine

## 3 – Verify

On the machines which are to be monitored by LogicMonitor, make sure that the GPO is applied. To force an update:

- In a command prompt: type **gpupdate /force**
- Ensure that the GPO is applied: Enter **gpresult /r**
- Under **COMPUTER SETTINGS** in the printout, look for **WMI Access** (the GPO we created) under the **Applied Group Policy Objects**. If it is listed there, it means that it is applied to the machine.
- Restart the target machine if using the WMI startup script to trigger the script execution.
- Add the machine to LogicMonitor and add the required properties **wmi.user** and **wmi.pass** for **CONTOSO\wmiuser**
- Verify the discovery result

# 4 - Service Monitoring

Even though we now have access to query WMI and all the namespaces it will still not allow you to query windows service information as that also requires changes to the **Service Control Manager**. In order to succesfully monitor windows services you will need to perform the following steps on the target machines you wish to monitor service status for:

- From a machine with the ActiveDirectory PS module installed run the following command to get the SID value for your **wmiuser** account:

```powershell
Get-ADUser -Identity 'wmiuser' | select SID
```

- From the Windows command prompt, run the following command to retrieve the current SDDL for the Services Control Manager. The SDDL is saved in the file called file.txt:

```
sc sdshow scmanager > file.txt
```

- The SDDL output looks something like this:

```
D:(A;;CC;;;AU)(A;;CCLCRPRC;;;IU)(A;;CCLCRPRC;;;SU)(A;;CCLCRPWPRC;;;SY)(A;;KA;;;BA)S:(AU;FA;KA;;;WD)(AU;OIIOFA;GA;;;WD)
```

- Copy the section of the SDDL from the exported file.txt that ends in IU (Interactive Users). This section is one complete bracketed clause ie **(A;;CCLCRPRC;;;IU)**. Paste this clause directly after the clause you copied from.
- In the new text, replace IU with the user SID of the **wmiuser**
- The new SDDL should look something like:

```
D:(A;;CC;;;AU)(A;;CCLCRPRC;;;IU)(A;;CCLCRPRC;;;S-1-5-21-214A909598-1293495619-13Z157935-75714)(A;;CCLCRPRC;;;SU)(A;;CCLCRPWPRC;;;SY)(A;;KA;;;BA) S:(AU;FA;KA;;;WD)(AU;OIIOFA;GA;;;WD)
```

- Run the following command with your modified SDDL to update the permissions to include your wmiuser account:

```
sc sdset scmanager "D:(A;;CC;;;AU)(A;;CCLCRPRC;;;IU)(A;;CCLCRPRC;;;<SID VALUE FOR WMISUER>)(A;;CCLCRPRC;;;SU)(A;;CCLCRPWPRC;;;SY)(A;;KA;;;BA) S:(AU;FA;KA;;;WD)(AU;OIIOFA;GA;;;WD)
"
```

# 5 – Additional Information

We recommend turning off UAC filtering on the target machines. It can be done by setting a registry key manually or through a GPO.
UAC can in some cases filter information through WMI so that the information is not as complete as it could be. Usually you do not need to do this step, but if information is missing, do the following on the target machine:

- Open regedit
- Add or edit the DWORD key to the value 1:

```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\system\LocalAccountTokenFilterPolicy
0 = Remote UAC access token filtering is enabled.
1 = Remote UAC is disabled.
```

- Close regedit

#### Note: It is recommended that you test these steps and ensure they will work for your environment. This is not an offical LogicMonitor repository and is simply to be used as guidance.