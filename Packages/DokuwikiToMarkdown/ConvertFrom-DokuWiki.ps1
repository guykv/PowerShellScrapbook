[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]
    $Path,

    [Parameter(Mandatory=$true)]
    [string]
    $Destination,

    [Parameter()]
    [string]
    $AttachmentMapPath = "$PSScriptRoot\attachmentmap.json"
)

$ErrorActionPreference = 'Stop'

. $PSScriptRoot\Functions.ps1

function ConvertFrom-DokuWikiPageName
{
    param (
        [Parameter()]
        [string]
        $Name
    )

    if (-not $Name)
    {
        return $Name
    }

    if ($Name.Length -eq 1)
    {
        return $Name.ToUpper()
    }

    $converted = ([string]$Name[0]).ToUpper() + $Name.Substring(1)
    $converted.Replace('-', '%2D').Replace('_', '-')
}

$mediaRoot = Join-Path -Path $Path -ChildPath media
$attachmentMap = Read-AttachmentMap -AttachmentMapPath $AttachmentMapPath

foreach ($mediaItem in (Get-ChildItem -Path $mediaRoot -Recurse -File))
{
    $fullPath = $mediaItem.FullName
    $filename = Split-Path -Path $fullPath -Leaf
    $ext = $mediaItem.Extension
    $parent = Split-Path -Path $fullPath -Parent
    $intermediatePath = $parent.Replace($mediaRoot, '')
    $namespace = $intermediatePath.Replace('\', ':')
    $dokuWikiPath = "$namespace`:$filename" -replace '^:', ''
    
    if ($attachmentMap.ContainsKey($dokuWikiPath))
    {
        $image = $image.$dokuWikiPath
    }
    else
    {
        $newGuid = [Guid]::NewGuid()
        if ($mediaItem.Extension -in @('.png', '.jpg', '.gif', '.bmp'))
        {
            $mdFilename = "image-$newGuid$ext"
        }
        else
        {
            $mdFilename = "$($mediaItem.BaseName)-$newGuid$ext"
        }

        $image = New-Object -TypeName PSObject -Property @{
            Name = $mediaItem.Name
            DokuWikiPath = $dokuWikiPath
            MdPath = "/.attachments/$mdFilename"
        }

        $attachmentMap.$dokuWikiPath = $image
    }
}

Write-AttachmentMap -AttachmentMapPath $AttachmentMapPath -AttachmentMap $attachmentMap

$pageRoot = Join-Path -Path $Path -ChildPath pages
$namespaces = @()
foreach ($pagePath in (Get-ChildItem -Path $pageRoot -Filter *.txt -Recurse))
{
    $fullPath = $pagePath.FullName
    $filename = Split-Path -Path $fullPath -Leaf
    $parent = Split-Path -Path $fullPath -Parent
    $intermediatePath = $parent.Replace($pageRoot, '')
    $namespace = $intermediatePath.Replace('\', ':') -replace '^:', ''
    if ($namespaces -notcontains $namespace)
    {
        $namespaces += $namespace
    }

    $name = ConvertFrom-DokuWikiPageName -Name ($filename.Replace('.txt', ''))
    $destinationPath = "$Destination\$intermediatePath\$name`.md"
    $page = @{
        Name = $name
        Path = $fullPath
        Namespace = $namespace
        Destination = $destinationPath
    }

    $destinationParent = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $destinationParent -PathType Container))
    {
        Write-Warning $destinationParent
        New-Item -Path $destinationParent -ItemType Container | Out-Null
    }
    
    & $PSScriptRoot\Convert-DokuWikiPage.ps1 @page -AttachmentMapPath $AttachmentMapPath | Set-Content -Path $destinationPath -Encoding UTF8
}

Write-Host "Done."
