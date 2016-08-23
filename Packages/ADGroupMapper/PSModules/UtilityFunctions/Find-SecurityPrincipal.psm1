#requires -version 2.0

Function Find-SecurityPrincipal
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
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[string[]]$SAMAccountName,
		
		[Parameter()]
		[string]$Server,
		
		[Parameter()]
		[switch]$UseSSL
    )
    
    Begin
    {
		$nc = Get-DefaultNamingContext -Server $Server -UseSSL:$UseSSL
        $search = New-Object System.DirectoryServices.DirectorySearcher($nc)
    }
    
    Process
    {
        $search.Filter = "(sAMAccountName=$SAMAccountName)"
        $res = $search.FindOne()
        if ($res)
        {
            Write-Output $res.GetDirectoryEntry()
        }
		else
		{
			Write-Warning "Security principal $SAMAccountName not found"
		}
    }
}
