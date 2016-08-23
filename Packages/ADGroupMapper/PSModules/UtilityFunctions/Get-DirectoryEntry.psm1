#requires -version 2.0

Function Get-DirectoryEntry
{
    <#
        .Synopsis
        
        .Description
        
        .Parameter x
        
        .Example
        
    #>
    [CmdletBinding()]
    Param
    (
		[Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[string[]]$Path,
		
		[Parameter()]
		[string]$Server,
		
		[Parameter()]
		[string]$UserName,
		
		[Parameter()]
		[string]$Password,
		
		[Parameter()]
		[switch]$UseSSL
    )
	
	Begin
	{
		$auth = "Secure"
		$prefix = "LDAP://"
		if ($Server)
		{
			$auth += ",ServerBind"
			$prefix += "$Server/"
		}
		
		if ($UseSSL)
		{
			$auth += ",SecureSocketsLayer"
		}
	}
	
	Process
	{
		foreach ($p in $Path)
		{
			$adsPath = "$prefix$p"
			Write-Verbose "Getting directory entry from $adsPath using authentication flags $auth"
			if ($UserName -or $UseSSL)
			{
				$de = New-Object System.DirectoryServices.DirectoryEntry($adsPath, $UserName, $Password, $auth)
			}
			else
			{
				$de = [adsi]$adsPath
			}
			
			Write-Output $de
		}
	}
}
