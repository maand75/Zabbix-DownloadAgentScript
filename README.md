# Zabbix DownloadAgentScript
Script and template used to update Windows Zabbix Agent

# Installation Agent Update
Update the following parameters in the script
	[string]$repository = "https://zabbix.mycloud.com/repository",
	[string]$zabbixroot = "C:\Program Files\Zabbix"
	
$repository is the location where you put the new agent version and scripts
$zabbixroot is the root installation folder for the agent

Create a Scripts folder in the root of the Zabbix agent installation folder and create a folder called DownloadAgentScript in the newly created Scripts folder

Copy the DownloadAgentScript.conf to the /scripts folder and the DownloadAgentScript.ps1 to /Scripts/DownloadAgentScript/

Add the following to the existing zabbix_agentd.conf to include all existing external scripts when starting agent
	Include=C:\Program Files\zabbix\scripts\*.conf

In the repository folder in the website put version of zabbix_agentd.exe, zabbix_get.exe and zabbix_sender.exe you want to update to, for example 5.2.0

Also create a file 'zabbix_agentd.txt' containing the version of the agent that are in the repository


# Zabbix Agent Update Item
The following item will download the zabbix_agentd.txt and compare the version written in the file with the version installed in '$ZabbixRoot\Bin'. If version is higher then it will download files, kill the current zabbix_agentd.exe process, replace the executables and start the agent again

The script will return the version of the agent installed so the current version installed can be viewed in the Item data

Create a new item:<br/>
	Name: Script UpdateAgent<br/>
	Type: Zabbix agent/Zabbix agent (active)<br/>
	Key: DownloadAgentScript[UpdateAgent]<br/>
	Type of Information: Text<br/>
	Update Interval: 15m (for testing)<br/>
	Application: Agent Script<br/>
	
# Zabbix Template Distribution/Update
DownloadAgentScript can also be used to create an item within your existing templates you are using so agents assigned the template will automatically download the configuration file and scripts to the '$ZabbixRoot\Scripts' folder

Add the following rows in the configuration file it the template only contains one script
	'# Version:1'
	
And if the template containts multiple scripts or script name is not the same as the name of the configuration file add the following with the name of all the scripts with a ; delimiter:
	'# Version:1'
	'# DownloadScripts:TemplateScript1.ps1;TemplateScript2.ps1;TemplateScript3.ps1'

Create a folder with the same name of the configuration file (.conf) and copy the script(s) to this folder. See SampleTemplate1 and SampleTemplate2

To download and update new version of the DownloadAgentScript create the following item:
	Name: Script DownloadAgentScript
	Type: Zabbix agent/Zabbix agent (active)
	Key: DownloadAgentScript[DownloadAgentScript]
	Type of Information: Numeric (unassigned)
	Units: version
	Update Interval: 15m (for testing)
	Application: Agent Script
	
The DownloadAgentScript will download the $repository/DownloadAgentScript.conf and read the version:X and if it already exists it will compare version and start updating if newer or download if it does not exists

The script will return the version of the script that is installed

If you update a script in the repository just increase the version number in the configuration file.

To send out and update scripts for other templates just add the configuration file for the template in the repository and create a folder with the same basename as the configuration file and place the scripts in this folder.
You may have to modify the configuration file to the correct path of the scripts in the folder that it will download.
Add Version and DownloadScripts if needed in the configuration file

Then create an item in the template that contains the scripts
	Name: Script <Name of Template>
	Type: Zabbix agent/Zabbix agent (active)
	Key: DownloadAgentScript[<Filename of configuration file without .conf extension>]
	Type of Information: Numeric (unassigned)
	Units: version
	Update Interval: 15m (for testing)
	Application: Agent Script
	
If you then get a newer version of the scripts for the template just update them in the repository and increase the version
