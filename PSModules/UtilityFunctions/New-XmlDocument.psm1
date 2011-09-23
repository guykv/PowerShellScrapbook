#requires -version 2.0

Function New-XmlDocument
{
    <#
        .Synopsis

        .Description

        .Parameter x

        .Outputs

        .Example

    #>
    [CmdletBinding()]
    Param
    (
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[string]$DocumentElementName
    )
    
    Begin
    {
    }

    Process
    {
        $xml = New-Object System.Xml.XmlDocument
        [Void]$xml.AppendChild($xml.CreateXmlDeclaration('1.0', 'UTF-8', $null))
        [Void]$xml.AppendChild($xml.CreateElement($DocumentElementName))
		Write-Output $xml
    }
    
    End
    {
    }
}
