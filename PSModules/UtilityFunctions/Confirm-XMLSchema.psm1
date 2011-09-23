#requires -version 2.0

Function Confirm-XMLSchema
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
        [Parameter(Mandatory=$true, Position=0)]
		[string]$XSDFile,
		
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
		[string[]]$XMLFile
    )
    
    Begin
    {
        $xsdPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($XSDFile)
        if (-not (Test-Path $xsdPath))
        {
            throw "XSD schema file $xsdPath doesn't exist"
        }
        
        $schemas = New-Object System.Xml.Schema.XmlSchemaSet
        $xmlReader = New-Object System.Xml.XmlTextReader($xsdPath)
        $schemas.Add($null, $xmlReader) | Out-Null
        $xmlReader.Close()
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.ValidationType = [System.Xml.ValidationType]::Schema
        $settings.Schemas = $schemas
    }

    Process
    {
		foreach ($f in $XMLFile)
		{
	        $xmlPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($f)
	        if (-not (Test-Path $xmlPath))
	        {
	            Write-Error "XML file $xmlPath doesn't exist"
	            break
	        }
	        
	        $fs = [System.IO.File]::OpenRead($xmlPath)
	        try
	        {
	            $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StreamReader($fs)), $settings)
	            while ($reader.Read())
	            {
	            }
	            
	            $true
	        }
	        finally
	        {
	            $fs.Dispose()
	        }
		}
    }
}
