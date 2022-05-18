function Read-AttachmentMap
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $AttachmentMapPath,

        [Parameter()]
        [switch]
        $Required
    )

    if (-not (Test-Path -Path $AttachmentMapPath -PathType Leaf))
    {
        if ($Required)
        {
            throw "Attachment mapping file not found ($AttachmentMapPath)"
        }

        return @{}
    }

    $data = ConvertFrom-Json -InputObject (Get-Content -Path $AttachmentMapPath | Out-String)
    $attachmentMap = @{}
    foreach ($d in $data)
    {
        $attachmentMap.$($d.DokuWikiPath) = $d
    }

    $attachmentMap
}

function Write-AttachmentMap
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $AttachmentMapPath,

        [Parameter(Mandatory = $true)]
        [Hashtable]
        $AttachmentMap
    )

    ConvertTo-Json -InputObject $AttachmentMap.Values -Compress | Set-Content -Path $AttachmentMapPath -Encoding UTF8
}
