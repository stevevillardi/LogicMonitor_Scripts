## WinRM LogicModule Support

This is a repository containing a number of core LM LogicModules that have been converted to querying host data via WSMan/WinRM rather then just straight WMI through DCOM. Benefits to this approach is easier firewall permissions as it eliminates the need for dynamic RPC ports down to just one port (http/5985 or https/5986). WinRM is also encrypted by default wether using http or https connections methods along with leveragingn Kerberos for authentication.

You will still need to have proper WMI permissions as WinRM is simply a mechanism to connect remotely to another machine. This LogicModule suite relies on the **Microsoft_PowerShell_WinRM_Info** PropertySource in order to set the required properties needed utilize a WinRM connection.

In additon to the property source you will also need to specify a **winrm.user** and **winrm.pass** property on the devices you wish to leverage these module on.

Below is the current list of converted LM core modules that can be obtained through the LM Exchange or you can download the XMl/JSON exports of these modules from the **LogicModules** folder in this repository.

**PropertySouces:**

- Microsoft_Powershell_WinRM_Info - EKMKRE

**DataSources:**

- WinIf_WinRM - 4MNKA2
- WinMemory64_WinRM - EEFZPL
- WinOS_WinRM - NHEPAK
- WinVolumeUsage_WinRM - 92YTW7
- WinCPUCore*WinRM - 7REECW *(In Security Review)*
- WinCPU_WinRM - 4FFRLG
- WinLogicalDrivePerformance_WinRM - JG3W2A
- WinPhysicalDrive_WinRM - 6CEKC7
- WinTCP_WinRM - C7H24G
- WinUDP_WinRM - XZYCYH
- WinSystemUptime_WinRM - 6XYDPG
- Windows_WMITimeOffset_WinRM - 4RXPH4
- Terminal Services_WinRM - FZ7P2F
- WinServer_WinRM - KM44RP
- Microsoft*Windows_Services_WinRM - Z4LYAN *(In Security Review)*
- WinProcessStats*WinRM - X4KMMP *(In Security Review)*
- Microsoft*Windows_Scheduled_Tasks_WinRM - 97JXTY *(In Security Review)*

**Notes:** If a customer is looking to leverage WinRM over HTTPS they must have a non self-signed cert that allows for **Server Authenticaiton** imported into the local machines certificate manager that has a CN that matches the fqdn of the local machine. Keep in mind that even if using WinRM over HTTP all authenticaion after the initial conneciton will be encrypted either way.
