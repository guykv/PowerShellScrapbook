Function Confirm-XmlSchema
{
    <#
        .Synopsis
        Confirms that a given XML file conforms to the specified
        XSD schema
        .Description
        This function uses the built in XML API to confirm that
        XML files conforms to a specific XSD schema definition.
        If the validation fails, an error is thrown.
        .Parameter XsdPath
        Path to the XSD schema file
        .Parameter XmlPath
        One or more paths to XML files to validate
        .Notes
        Author: Guy Kvaernberg <me@guyk.no>
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
