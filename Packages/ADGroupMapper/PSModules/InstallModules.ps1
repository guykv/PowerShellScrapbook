Param
(
	[string]$ModuleSource = $(Split-Path $MyInvocation.MyCommand.Path -Parent),
	[switch]$AllUsers
)

if ($AllUsers)
{
	$dest = "$PSHOME\Modules"
}
else
{
	$personal = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name Personal).Personal
	$dest = "$personal\WindowsPowerShell\Modules"
}

if (-not (Test-Path $dest))
{
	[void](New-Item -Path $dest -ItemType Directory)
}

foreach ($m in Get-ChildItem -Path $ModuleSource | Where-Object { $_.PSIsContainer })
{
	$name = $m.Name
	$destDir = "$dest\$name"
	if (Test-Path $destDir)
	{
		Remove-Item $destDir -Recurse -Force
	}
	
	Write-Progress -Activity "Installing modules" -Status "Installing $name"
	Copy-Item -Path $m.FullName -Destination $destDir -Recurse
}

Write-Progress -Activity "Installing modules" -Status "Done" -Completed
