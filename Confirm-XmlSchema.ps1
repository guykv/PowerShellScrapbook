Function Confirm-XmlSchema
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
		$XsdPath,
		
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		$XmlPath
    )
    
    Begin
    {
		$xsd = Get-AbsolutePath -FilePath $XsdPath
        if (-not (Test-Path $xsd))
        {
            throw "XSD schema file $xsd doesn't exist"
        }
        
        $schemas = New-Object System.Xml.Schema.XmlSchemaSet
        $xmlReader = New-Object System.Xml.XmlTextReader($xsd)
        $schemas.Add($null, $xmlReader) | Out-Null
        $xmlReader.Close()
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.ValidationType = [System.Xml.ValidationType]::Schema
        $settings.Schemas = $schemas
    }

    Process
    {
		$xml = Get-AbsolutePath -FilePath $XmlPath
        if (-not (Test-Path $xml))
        {
            Write-Error "XML file $xml doesn't exist"
            break
        }
        
        $fs = [System.IO.File]::OpenRead($xml)
        try
        {
            $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StreamReader($fs)), $settings)
            while ($reader.Read())
            {
            }
            
            Write-Output $true
        }
        finally
        {
            $fs.Dispose()
        }
    }
}