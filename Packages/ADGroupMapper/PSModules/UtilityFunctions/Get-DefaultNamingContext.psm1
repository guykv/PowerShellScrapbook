#requires -version 2.0

Function Get-DefaultNamingContext
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
		[Parameter(Position=0)]
		[string]$Server,
		
		[Parameter()]
		[string]$UserName,
		
		[Parameter()]
		[string]$Password,
		
		[Parameter()]
		[switch]$UseSSL
    )
	
	$auth = "None"
	if ($Server)
	{
		$auth += ",ServerBind"
	}
	
	if ($UseSSL)
	{
		$auth += ",SecureSocketsLayer"
	}
	
	$de = Get-DirectoryEntry -Path RootDSE -Server $Server -UserName $UserName -Password $Password -UseSSL:$UseSSL
	$nc = $de.defaultNamingContext
	if ($nc)
	{
		Write-Output $nc
	}
	else
	{
		Write-Error "Failed to determine default naming context"
	}
}
