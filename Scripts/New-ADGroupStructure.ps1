#requires -version 2.0

<#
    .Synopsis
    Creates organizational units and groups in Active Directory from XML
    configuration
    .Description
    The script will work also if some or all of the OUs or groups already exist.
    The OU descriptions will in such case be corrected if they are different
    than what is configured, while the groups are left unchanged. Example of
    the content of a group definition file:

    <?xml version="1.0" encoding="utf-8"?>
    <GroupCreationTool >
	    <Variable Name="Corp" Value="Contoso Corporation" />
	    <OrganizationalUnit Name="%Corp%" Description="All objects for %Corp%" />
	    <OrganizationalUnit Name="RoleGroups" Description="Company roles" Parent="%Corp%" />
	    <OrganizationalUnit Name="SecGroups" Description="Security groups" Parent="%Corp%" />
	    <GroupDefinitions Container="RoleGroups" Prefix="RoleGroup-" Suffix=" GG" Scope="Global" Category="Security" >
		    <Group Name="Managers" Description="All managers in %Corp%" />
		    <Group Name="Sales" Description="All sales reps in %Corp%" />
		    <Group Name="Everybody" Description="All employees in %Corp%" >
			    <Member Name="Managers" />
			    <Member Name="Sales" />
		    </Group>
	    </GroupDefinitions >
	    <GroupDefinitions Container="SecGroups" Prefix="SecGroup-" Suffix=" LG" Scope="DomainLocal" Category="Security" >
		    <Group Name="FileShareRO" Description="Read-Only access to the file share" >
			    <Member Name="Everybody" />
		    </Group>
		    <Group Name="FileShareRW" Description="Read/Write access to the file share" >
			    <Member Name="Managers" />
			    <Member Name="Domain Admins" />
		    </Group >
		    <Group Name="PrintColor" Description="Can print in color" >
			    <Member Name="Sales" />
		    </Group >
	    </GroupDefinitions >
    </GroupCreationTool>

    .Parameter GroupDefinitions
    Path to a Group definitions XML file
    .Parameter PassThru
    Whether the group objects are to be output from the script
    .Parameter GetSchema
    Outputs the group definition XSD schema
#>
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'GroupDefinitions')]
Param
(
    [Parameter(ParameterSetName = 'GroupDefinitions', Mandatory = $true)]
    $GroupDefinitions,

    [Parameter(ParameterSetName = 'GroupDefinitions')]
    [switch]$PassThru,

    [Parameter(ParameterSetName = 'GetSchema')]
    [switch]$GetSchema
)

Import-Module -Name ActiveDirectory -ErrorAction Stop

$CONSTANTS = DATA {
    @{
        XML_SCHEMA = @"
<?xml version="1.0"?>
<xs:schema attributeFormDefault="unqualified"
           elementFormDefault="qualified"
           xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="GroupCreationTool">
    <xs:complexType>
      <xs:sequence>
        <xs:element ref="Variable" minOccurs="0" maxOccurs="unbounded" />
        <xs:element ref="OrganizationalUnit" minOccurs="0" maxOccurs="unbounded" />
        <xs:element ref="GroupDefinitions" minOccurs="0" maxOccurs="unbounded" />
      </xs:sequence>
    </xs:complexType>
  </xs:element>
  
  <xs:element name="Variable">
    <xs:complexType>
      <xs:attribute name="Name" type="xs:string" use="required" />
      <xs:attribute name="Value" type="xs:string" use="required" />
    </xs:complexType>
  </xs:element>

  <xs:element name="OrganizationalUnit">
    <xs:complexType>
      <xs:attribute name="Name" type="xs:string" use="required" />
      <xs:attribute name="Description" type="xs:string" use="optional" />
      <xs:attribute name="Parent" type="xs:string" use="optional" />
    </xs:complexType>
  </xs:element>
  
  <xs:element name="GroupDefinitions">
    <xs:complexType>
	  <xs:sequence>
	    <xs:element ref="Group" minOccurs="0" maxOccurs="unbounded" />
	  </xs:sequence>
      <xs:attribute name="Container" type="xs:string" use="optional" />
      <xs:attribute name="Prefix" type="xs:string" use="optional" />
      <xs:attribute name="Suffix" type="xs:string" use="optional" />
      <xs:attribute name="Scope" type="GroupScopeType" use="optional" />
      <xs:attribute name="Category" type="GroupCategoryType" use="optional" />
    </xs:complexType>
  </xs:element>
  
  <xs:element name="Group">
    <xs:complexType>
	  <xs:sequence>
	    <xs:element ref="Member" minOccurs="0" maxOccurs="unbounded" />
	  </xs:sequence>
      <xs:attribute name="Name" type="xs:string" use="required" />
      <xs:attribute name="Description" type="xs:string" use="optional" />
    </xs:complexType>
  </xs:element>
  
  <xs:element name="Member">
    <xs:complexType>
      <xs:attribute name="Name" type="xs:string" use="required" />
    </xs:complexType>
  </xs:element>

  <xs:simpleType name="GroupScopeType">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Global" />
      <xs:enumeration value="DomainLocal" />
      <xs:enumeration value="Universal" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="GroupCategoryType">
    <xs:restriction base="xs:string">
      <xs:enumeration value="Security" />
      <xs:enumeration value="Distribution" />
    </xs:restriction>
  </xs:simpleType>
  
</xs:schema>
"@
        DEFAULT_PARENT = "%DefaultNamingContext%"

        DEFAULT_GROUP_OPTS = @{
            Parent = "%DefaultNamingContext%"
            Scope = "Global"
            Category = "Security"
        }

    }
}

Function Confirm-XmlSchema
{
    <#
        .Synopsis
        Confirms that a given XML file conforms to the specified
        XSD schema.
        .Description
        This function uses the built in XML API to confirm that
        XML files conforms to a specific XSD schema definition.
        If the validation fails, an error is thrown.
        .Parameter XsdPath
        Path to the XSD schema file
        .Parameter XmlPath
        One or more paths to XML files to validate
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
	    [string]$XsdPath,
		
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Alias('Path')]
	    [string[]]$XmlPath
    )
    
    Begin
    {
	    $xsd = Get-Item -Path $XsdPath -ErrorAction Stop
        $schemas = New-Object System.Xml.Schema.XmlSchemaSet
        $xmlReader = New-Object System.Xml.XmlTextReader($xsd.FullName)
        $schemas.Add($null, $xmlReader) | Out-Null
        $xmlReader.Close()
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.ValidationType = [System.Xml.ValidationType]::Schema
        $settings.Schemas = $schemas
    }

    Process
    {
        foreach ($path in $XmlPath)
        {
		    $xml = Get-Item -Path $path
            if (-not $xml)
            {
                continue
            }

            $fs = [System.IO.File]::OpenRead($xml.FullName)
            try
            {
                $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StreamReader($fs)), $settings)
                while ($reader.Read())
                {
                }
            }
            finally
            {
                $fs.Dispose()
            }
        }
    }
}

Function New-ParameterizedGroup
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param
	(
		[Parameter()]
		[string]$Prefix,
		
		[Parameter()]
		[string]$Suffix,
		
		[Parameter()]
		[string]$Container = "CN=Users,$([string]([adsi]'LDAP://rootDse').defaultNamingContext)",
		
		[Parameter()]
		[System.Nullable[Microsoft.ActiveDirectory.Management.ADGroupScope]]$GroupScope = 'DomainLocal',

        [Parameter()]
        [System.Nullable[Microsoft.ActiveDirectory.Management.ADGroupCategory]]$GroupCategory = 'Security',
		
		[Parameter(Mandatory = $true)]
		[string]$BaseName,

        [Parameter()]
        [string]$Description,
		
		[Parameter()]
		[switch]$PassThru
	)
	
	if (-not ($WhatIfPreference -or [adsi]::Exists("LDAP://$Container")))
	{
		throw "AD container '$Container' doesn't exist"
	}

	$groupName = $Prefix + $BaseName + $Suffix
	$existing = Get-ADObject -Filter { sAMAccountName -eq $groupName -or name -eq $groupName }
	if ($existing -eq $null)
	{
		New-ADGroup -GroupCategory $GroupCategory -GroupScope $GroupScope -Name $groupName -Description $Description -Path $Container -PassThru:$PassThru -WhatIf:$WhatIfPreference
	}
	else
	{
		Write-Warning "An object with the name '$groupName' already exists, in the location $($existing.DistinguishedName)"
		if ($PassThru)
		{
            if ($existing.ObjectClass -contains 'group')
            {
    			Write-Output (Get-ADGroup -Identity $existing.DistinguishedName)
            }
            else
            {
                Write-Error "The existing object at $($existing.DistinguishedName) is not a group"
            }
		}
	}
}

Function Use-SubstitutionVariables
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [hashtable]$Variables,

        [Parameter(ValueFromPipeline = $true)]
        [string[]]$Value,

        [Parameter()]
        [string]$MarkerChar = "%"
    )

    Begin
    {
        $markers = @{}
        $Variables.Keys | ForEach-Object -Process { $markers."$MarkerChar$_$MarkerChar" = $Variables.$_ }
    }

    Process
    {
        foreach ($v in $Value)
        {
            foreach ($m in $markers.Keys)
            {
                $v = $v -replace $m, $markers.$m
            }

            $v
        }
    }
}

Function Use-GroupDefinitions
{
	<#
		.Synopsis
		
		.Description
		
		.Parameter Parameter1
		
		.Example
		
	#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param
	(
		[Parameter(Mandatory = $true)]
		[string]$GroupDefinitions,

        [Parameter()]
        [switch]$PassThru
	)

	if (-not (Test-Path -Path $GroupDefinitions -PathType Leaf))
	{
		throw "The membership map file '$GroupDefinitions' doesn't exist"
	}

    if (-not (Confirm-XmlSchema -SchemaXsd $CONSTANTS.XML_SCHEMA -XmlFile $GroupDefinitions))
    {
        throw "The XML in '$GroupDefinitions' failed schema validation"
    }

    $xml = [xml](Get-Content $GroupDefinitions)

    $variables = @{
        DefaultNamingContext = ([adsi]"LDAP://RootDSE").defaultNamingContext
    }

    foreach ($v in $xml.DocumentElement.Variable)
    {
        Write-Verbose "Defining variable $($v.Name)"
        $variables.$([string]$v.Name) = [string]$v.Value
    }

    $containers = @{}
    foreach ($ou in $xml.DocumentElement.OrganizationalUnit)
    {
        $ouDef = @{
            Parent = $CONSTANTS.DEFAULT_PARENT
        }

        # Perform variable substition
        foreach ($a in 'Name', 'Description', 'Parent')
        {
            if ($ou.$a)
            {
                $ouDef.$a = [string]$ou.$a
            }

            $ouDef.$a = $ouDef.$a | Use-SubstitutionVariables -Variables $variables
        }

        # Check if a cached parent name is used
        if ($containers.ContainsKey($ouDef.Parent))
        {
            $ouDef.Parent = $containers.($ouDef.Parent)
        }

        $ouDef.Path = "OU=$($ouDef.Name),$($ouDef.Parent)"
        if (-not ($WhatIfPreference -or [adsi]::Exists("LDAP://$($ouDef.Parent)")))
        {
            throw "The parent container '$($ouDef.Parent)' doesn't exist"
        }

        if (-not [adsi]::Exists("LDAP://$($ouDef.Path)"))
        {
            New-ADOrganizationalUnit -Name $ouDef.Name -Path $ouDef.Parent -Description $ouDef.Description -WhatIf:$WhatIfPreference
        }
        else
        {
            Write-Warning "The OU $($ouDef.Path) already exists"
            $object = Get-ADOrganizationalUnit -Identity $ouDef.Path -Properties Description

            if ($object.Description -cne $ouDef.Description)
            {
                Write-Verbose "Changing description to '$($ouDef.Description)' from '$($object.Description)' on $($ouDef.Path)"
                $object | Set-ADOrganizationalUnit -Description $ouDef.Description -WhatIf:$WhatIfPreference
            }
        }

        $containers.$($ouDef.Name) = $ouDef.Path
    }

    $referenceMap = @{}
    $memberships = @{}
    foreach ($def in $xml.DocumentElement.GroupDefinitions)
    {
        $opts = $CONSTANTS.DEFAULT_GROUP_OPTS.Clone()
        'Container', 'Prefix', 'Suffix', 'Scope', 'Category' | Where-Object { $def.$_ } | ForEach-Object { $opts.$_ = $def.$_ | Use-SubstitutionVariables -Variables $variables }
        if ($containers.ContainsKey($opts.Container))
        {
            $opts.Container = $containers.$($opts.Container)
        }

        foreach ($group in $def.Group)
        {
            $baseName = [string]$group.Name | Use-SubstitutionVariables -Variables $variables
            $fullName = $opts.Prefix + $baseName + $opts.Suffix
            $groupDn = "CN=$fullName,$($opts.Container)"
            $referenceMap.$baseName = $fullName
            $description = $group.Description | Use-SubstitutionVariables -Variables $variables
            $groupObject = New-ParameterizedGroup -BaseName $baseName -Description $description -Prefix $opts.Prefix -Suffix $opts.Suffix -Container $opts.Container -GroupScope $opts.Scope -GroupCategory $opts.Category -PassThru
            if ($PassThru -and $groupObject)
            {
                Write-Output $groupObject
            }

            if ($group.Member)
            {
                foreach ($member in $group.Member)
                {
                    if (-not $memberships.ContainsKey($groupDn))
                    {
                        $memberships.$groupDn = @()
                    }

                    $memberships.$groupDn += [string]$member.Name
                }
            }
        }
    }

    # Check memberships
    foreach ($groupDn in $memberships.Keys)
    {
        Write-Verbose "Checking memberships of $groupDn"
        if ([adsi]::Exists("LDAP://$groupDn"))
        {
            $actualMembers = Get-ADGroupMember -Identity $groupDn | ForEach-Object { Get-ADObject -Identity $_ -Properties sAMAccountName }
            $membersMissing = @()
            foreach ($memberName in $memberships.$groupDn)
            {
                if ($referenceMap.ContainsKey($memberName))
                {
                    $memberName = $referenceMap.$memberName
                }

                $alreadyMember = $false
                foreach ($am in $actualMembers)
                {
                    if ($am.Name -eq $memberName -or $am.sAMAccountName -eq $memberName -or $am.distinguishedName -eq $memberName)
                    {
                        Write-Verbose "$memberName already member of $groupDn"
                        $alreadyMember = $true
                        break
                    }
                }

                if (-not $alreadyMember)
                {
                    $membersMissing += $memberName
                }
            }

            if ($membersMissing.Length -gt 0)
            {
                Write-Verbose "Adding missing memberships to $groupDn"
                Add-ADGroupMember -Identity $groupDn -Members $membersMissing -WhatIf:$WhatIfPreference
            }
        }
    }
}

if ($GetSchema)
{
    $CONSTANTS.XML_SCHEMA
    break
}

Use-GroupDefinitions -GroupDefinitions $GroupDefinitions -PassThru:$PassThru
