#requires -version 2.0

#region Add-Mapping
Function Add-Mapping
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
		[Alias("Path")]
		[string]$XMLPath = "$(Get-Location)\ADGroupMap.xml",
		
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[string]$ADGroup,
		
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[string]$MapGroup,
		
		[Parameter()]
		[switch]$VerifyADGroup,
		
		[Parameter()]
		[string]$XSDSchemaPath = "$PSScriptRoot\ADGroupMap.xsd"
    )
    
    Begin
    {
		if (Test-Path $XMLPath)
		{
			if (Confirm-XMLSchema -XSDFile "$PSScriptRoot\ADGroupMap.xsd" -XMLFile $XMLPath)
			{
				$xml = [xml](Get-Content -Path $XMLPath)
			}
			else
			{
				throw "The XML file '$XMLPath' does not conform to the required schema"
			}
		}
		else
		{
			$xml = New-XmlDocument ADGroupMap
		}
		
		$changed = $false
    }
    
    Process
    {
		if ($VerifyADGroup)
		{
			$g = Find-SecurityPrincipal $ADGroup
			if ($g)
			{
				if ($g.objectClass -notcontains "group")
				{
					Write-Error "The AD security principal '$ADGroup' was found, but it is not a group"
					continue
				}
			}
			else
			{
				Write-Error "The AD group '$ADGroup' could not be found"
				continue
			}
		}
		
		$node = $xml.DocumentElement.SelectSingleNode("Group[@Name='$MapGroup' and @ADName='$ADGroup']")
		if ($node)
		{
			Write-Warning "The AD group '$ADGroup' is already mapped to '$MapGroup'"
		}
		else
		{
			$elem = $xml.DocumentElement.AppendChild($xml.CreateElement("Group"))
			$elem.SetAttribute("Name", $MapGroup)
			$elem.SetAttribute("ADName", $ADGroup)
			$changed = $true
		}
    }
	
	End
	{
		if ($changed)
		{
			$xml.Save($XMLPath)
			Write-Verbose "Wrote XML to $XMLPath"
		}
	}
}
#endregion

#region Get-MappedGroupMembers
Function Get-MappedGroupMembers
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
        [Parameter(ValueFromPipeline=$true, Position=0)]
		[Alias("Path")]
		[string[]]$XMLPath = "$(Get-Location)\ADGroupMap.xml",
		
		[Parameter()]
		[string]$OutputPath,
		
		[Parameter()]
		[switch]$IncludeDisabled,
		
		[Parameter()]
		[string]$Server,
		
		[Parameter()]
		[switch]$UseSSL,
		
		[Parameter()]
		[string]$XSDSchemaPath = "$PSScriptRoot\ADGroupMap.xsd"
    )
    
    Begin
    {
		$out = New-Object System.Collections.ArrayList
		$allUsers = New-Object System.Collections.ArrayList
    }
    
    Process
    {
		foreach ($path in $XMLPath)
		{
			if (-not (Test-Path $path))
			{
				Write-Error "The AD group map file '$path' doesn't exist"
				continue
			}
			
			if (-not (Confirm-XMLSchema -XSDFile $XSDSchemaPath -XMLFile $path))
			{
				continue
			}
			
			$xml = [xml](Get-Content $path)
			foreach ($groupElement in $xml.DocumentElement.Group)
			{
				foreach ($user in Get-ADGroupMembers -Group $groupElement.ADName -Server $Server -UseSSL:$UseSSL)
				{
					$de = Get-DirectoryEntry $user -Server $Server -UseSSL:$UseSSL
					if ((-not $de.AccountDisabled) -or $IncludeDisabled)
					{
						$sam = [string]$de.sAMAccountName
						if ($allUsers -contains $sam)
						{
							Write-Warning "The user '$sam' is member of more than one mapped groups. The membership in the group '$($groupElement.ADName)' is ignored."
						}
						else
						{
							[Void]$allUsers.Add($sam)
							$mapping = New-Object PSObject -Property @{
								UserName = [string]$de.sAMAccountName
								MappedGroup = [string]$groupElement.Name
							}
							
							if ($OutputPath)
							{
								[Void]$out.Add($mapping)
							}
							else
							{
								Write-Output $mapping
							}
						}
					}
				}
			}
		}
    }
	
	End
	{
		if ($OutputPath)
		{
			$xml = New-XmlDocument -DocumentElementName ADGroupMap
			foreach ($u in $out)
			{
				$elem = $xml.DocumentElement.AppendChild($xml.CreateElement("UserMapping"))
				$elem.SetAttribute("UserName", $u.UserName)
				$elem.SetAttribute("MappedGroup", $u.MappedGroup)
			}
			
			if ([System.IO.Path]::IsPathRooted($OutputPath))
			{
				$savePath = $OutputPath
			}
			else
			{
				$savePath = "$(Get-Location)\$OutputPath"
			}
			
			$xml.Save($savePath)
		}
	}
}
#endregion
