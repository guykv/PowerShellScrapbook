#requires -version 2.0

Function Get-ADGroupMembers
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
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
		[ValidateNotNullOrEmpty()]
		[Object[]]$Group,
		
		[Parameter()]
		[System.Collections.ArrayList]$IgnoreGroups,
		
		[Parameter()]
		[string]$Server,
		
		[Parameter()]
		[switch]$UseSSL
    )
    
    Begin
    {
		$visited = New-Object System.Collections.ArrayList
    }
    
    Process
    {
		foreach ($g in $Group)
		{
	        switch ($g.GetType().Name)
	        {
	            'DirectoryEntry' { $de = $g }
				
	            'String'
	            {
	                switch -regex ($g)
	                {
	                    "^LDAP://(.*)" { $de = Get-DirectoryEntry -Path $matches[1] }
	                    "^CN=" { $de = Get-DirectoryEntry -Path $g }
	                    default { $de = Find-SecurityPrincipal -SAMAccountName $g }
	                }
	            }
	            
	            default { throw "Illegal group object type '$($g.GetType().Name)'" }
	        }
	        
	        if ($de)
	        {
	            $res = @()
				[Void]$visited.Add([string]$de.distinguishedName)
				foreach ($groupDn in $de.Member | Where-Object { -not (($res -contains $_) -or ($visited -contains $_)) })
				{
	                $m = [adsi]"LDAP://$groupDn"
	                if ($m.objectClass -contains 'group')
	                {
	                    $res += Get-ADGroupMembers -Group $m -IgnoreGroups $visited
	                }
	                else
	                {
						$dn = $m.distinguishedName
						if ($res -notcontains $dn)
						{
		                    $res += $dn
						}
	                }
	            }
	            
	            Write-Output $res
	        }
		}
    }
}
