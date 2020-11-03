param(
	[string]$template,
	[string]$repository = "https://zabbix.mycloud.com/repository",
	[string]$zabbixroot = "C:\Program Files\Zabbix"
)

#Remove the repository and zabbixroot if this is added in the item as parameters

$progressPreference = 'silentlyContinue'
$psversion = Get-Host | Select-Object Version
if ($psversion.version.major -lt 3)
{
	[Net.ServicePointManager]::SecurityProtocol =  [Enum]::ToObject([Net.SecurityProtocolType], 3072)
}
else
{
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
function getFileVersion($filename)
{
	if (test-path "$zabbixroot\scripts\$filename")
	{
		foreach ($row in (Get-Content "$zabbixroot\scripts\$filename"))
		{
			if ($row -match "version")
			{
				return $row.split(":")[1]
				break
			}
		}
	}
	return 0
}

function getDownloadScripts($filename)
{
	if (test-path "$zabbixroot\scripts\$filename")
	{
		foreach ($row in (Get-Content "$zabbixroot\scripts\$filename"))
		{
			if ($row -match "DownloadScripts")
			{
				return $row.split(":")[1]
				break
			}
		}
	}
	return "false"
}

function updateAgent()
{
	if ($psversion.version.major -lt 3)
	{
		$WebClient = New-Object System.Net.WebClient
		$WebClient.DownloadFile("$repository/zabbix_agentd.txt","$zabbixroot\bin\zabbix_agentd.txt")	
	}
	else
	{
		Invoke-WebRequest $repository/zabbix_agentd.txt -OutFile "$zabbixroot\bin\zabbix_agentd.txt"
	}
	$newversion = get-content "$zabbixroot\bin\zabbix_agentd.txt"
	del "$zabbixroot\bin\zabbix_agentd.txt" -force
	$currentversion = (Get-Item "$zabbixroot\bin\zabbix_agentd.exe").VersionInfo.ProductVersion
	if ($newversion -gt $currentversion)
	{
		if ($psversion.version.major -lt 3)
		{
			$WebClient = New-Object System.Net.WebClient
			$WebClient.DownloadFile("$repository/zabbix_agentd.exe","$zabbixroot\bin\zabbix_agentd.exe.new")	
			$WebClient.DownloadFile("$repository/zabbix_get.exe","$zabbixroot\bin\zabbix_get.exe.new")	
			$WebClient.DownloadFile("$repository/zabbix_sender.exe","$zabbixroot\bin\zabbix_sender.exe.new")	
		}
		else
		{
			Invoke-WebRequest $repository/zabbix_agentd.exe -OutFile "$zabbixroot\bin\zabbix_agentd.exe.new"
			Invoke-WebRequest $repository/zabbix_get.exe -OutFile "$zabbixroot\bin\zabbix_get.exe.new"
			Invoke-WebRequest $repository/zabbix_sender.exe -OutFile "$zabbixroot\bin\zabbix_sender.exe.new"
		}
		taskkill /im zabbix_agentd.exe /f > $null
		
		mv "$zabbixroot\bin\zabbix_agentd.exe.new" "$zabbixroot\bin\zabbix_agentd.exe" -force
		mv "$zabbixroot\bin\zabbix_get.exe.new" "$zabbixroot\bin\zabbix_get.exe" -force
		mv "$zabbixroot\bin\zabbix_sender.exe.new" "$zabbixroot\bin\zabbix_sender.exe" -force
		
		net start "zabbix agent" > $null
		$newversion
	}
	else
	{
		$currentversion
	}
	
}
function downloadTemplate($name)
{
	$file = $name + ".conf"
	$newfile = $file + ".new"
	$currentversion = getFileVersion($file)
	if ($psversion.version.major -lt 3)
	{
		$WebClient = New-Object System.Net.WebClient
		$WebClient.DownloadFile("$repository/$file","$zabbixroot\scripts\$newfile")	
	}
	else
	{
		Invoke-WebRequest $repository/$file -OutFile "$zabbixroot\scripts\$newfile"
	}
	
	$newversion = getFileVersion("$newfile")
	
	if ($newversion -eq $currentversion)
	{
		del "$zabbixroot\scripts\$newfile" -force:$true
		$currentversion
	}
	elseif ($newversion -gt $currentversion)
	{
		move "$zabbixroot\scripts\$newfile" "$zabbixroot\scripts\$file" -force:$true
		$psname = $name + ".ps1"
		if (!(test-path "$zabbixroot\scripts\$name"))
		{
			mkdir "$zabbixroot\scripts\$name"
		}
		
		$downloadscripts = getDownloadScripts("$file")
		
		if ($downloadscripts -eq "false")
		{
			if ($psversion.version.major -lt 3)
			{
				$WebClient = New-Object System.Net.WebClient
				$WebClient.DownloadFile("$repository/$name/$psname","$zabbixroot\scripts\$name\$psname")	
			}
			else
			{
				Invoke-WebRequest $repository/$name/$psname -OutFile "$zabbixroot\scripts\$name\$psname"
			}
		}
		else
		{
			$scripts2download = $downloadscripts.split(";")
			foreach ($script in $scripts2download)
			{
				if ($psversion.version.major -lt 3)
				{
					$WebClient = New-Object System.Net.WebClient
					$WebClient.DownloadFile("$repository/$name/$script","$zabbixroot\scripts\$name\$script")	
				}
				else
				{
					Invoke-WebRequest $repository/$name/$script -OutFile "$zabbixroot\scripts\$name\$script"
				}			
			}
		}
		$newversion
		taskkill /im zabbix_agentd.exe /f > $null
		net start "zabbix agent" > $null
	}
	elseif ($newversion -lt $currentversion)
	{
		del "$zabbixroot\$newfile" -force:$true
		$currentversion
	}
}
if ($template -eq "UpdateAgent")
{
	updateAgent
}
else
{
	downloadTemplate($template)
}



