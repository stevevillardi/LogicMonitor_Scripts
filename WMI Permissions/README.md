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

### DCOM

- Right-click **WMI Access** (which is the GPO we just created), select Edit
- Go to Computer **Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> Security Options**
- Select Properties at: **DCOM: Machine Access Restrictions in Security Descriptor Definition Language (SDDL) syntax**
- Check the **Define this policy setting**
- Select **Edit Security …**
- Click **Add …**
- Under **Enter the object names to select:** Enter **wmiuser** and click **Check Names**. The user is now filled in automatically
- Click **OK**
- Select **wmiuser (wmiuser@contoso.local)**
- Under **Permissions**: Tick **Allow** on both **Local Access** and **Remote Access**
- Click **OK**
- Click **OK**
- Select Properties under: **DCOM: Machine Launch Restrictions in Security Descriptor Definition Language (SDDL) syntax**
- Check **Define this policy setting**
- Select **Edit Security …**
- Click **Add …**
- Under **Enter the object names to select:** Enter **wmiuser** and click **Check Names**. The user is now filled in automatically
- Click **OK**
- Select **wmiuser (wmiuser@contoso.local)**
- Under **Permissions**: Tick **Allow** at **Local Launch, Remote Launch, Local Activation** and **Remote Activation**
- Click **OK**
- Click **OK**

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

## 3 – Rights for WMI namespace

These settings can not be done with a regular GPO. _For a user who is not Admin this step is critical and must be done exactly as instructed below_. If not properly done, login attempts via WMI results in Access Denied. To set these settings via GPO you can use the following PS script as a startup script GPO task:

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

## 4 – Verify

On the machines which are to be monitored by LogicMonitor, make sure that the GPO is applied. To force an update:

- In a command prompt: type **gpupdate /force**
- Ensure that the GPO is applied: Enter **gpresult /r**
- Under **COMPUTER SETTINGS** in the printout, look for **WMI Access** (the GPO we created) under the **Applied Group Policy Objects**. If it is listed there, it means that it is applied to the machine.
- Add the machine to LogicMonitor and add the required properties **wmi.user** and **wmi.pass** for **CONTOSO\wmiuser**
- Verify the discovery result

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
