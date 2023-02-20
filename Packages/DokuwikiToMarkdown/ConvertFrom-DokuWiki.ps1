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
    $RootName = "DokuWiki",

    [Parameter()]
    [string]
    $AttachmentMapPath = "$PSScriptRoot\attachmentmap.json"
)

$ErrorActionPreference = 'Stop'

. $PSScriptRoot\Functions.ps1

$mdDestination = Join-Path -Path $Destination -ChildPath $RootName

Write-Host "Mapping media attachments"
$mediaRoot = (Get-Item -Path (Join-Path -Path $Path -ChildPath media)).FullName
$attachmentMap = Read-AttachmentMap -AttachmentMapPath $AttachmentMapPath
$attachmentCount = 0
foreach ($mediaItem in (Get-ChildItem -Path $mediaRoot -Recurse -File))
{
    $sourceFullPath = $mediaItem.FullName
    $sourceFilename = Split-Path -Path $sourceFullPath -Leaf
    $ext = $mediaItem.Extension
    $sourceParent = Split-Path -Path $sourceFullPath -Parent
    $sourceIntermediatePath = $sourceParent.Replace($mediaRoot, '')
    $namespace = $sourceIntermediatePath.Replace('\', ':')
    $dokuWikiPath = "$namespace`:$sourceFilename"
    
    if ($attachmentMap.ContainsKey($dokuWikiPath))
    {
        $image = $attachmentMap.$dokuWikiPath
    }
    else
    {
        $newGuid = [Guid]::NewGuid()
        if ($mediaItem.Extension -in @('.png', '.jpg', '.gif', '.bmp'))
        {
            $mdFilename = "image-$newGuid$ext"
            $isImage = $true
        }
        else
        {
            $mdFilename = "$($mediaItem.BaseName)-$newGuid$ext"
            $isImage = $false
        }

        $image = New-Object -TypeName PSObject -Property @{
            Name = $mediaItem.Name
            DokuWikiPath = $dokuWikiPath
            MdPath = "/.attachments/$mdFilename"
            IsImage = $isImage
        }

        $attachmentMap.$dokuWikiPath = $image
    }

    $destinationPath = Join-Path -Path $Destination -ChildPath $image.MdPath
    $sourceParentPath = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $sourceParentPath -PathType Container))
    {
        New-Item -Path $sourceParentPath -ItemType Container | Out-Null
    }

    Copy-Item -Path $sourceFullPath -Destination $destinationPath -Force | Out-Null
    $attachmentCount++
}

Write-AttachmentMap -AttachmentMapPath $AttachmentMapPath -AttachmentMap $attachmentMap
Write-Host "Mapped and copied $attachmentCount media attachments"

Write-Host "Mapping pages"
$sourceRoot = (Get-Item -Path (Join-Path -Path $Path -ChildPath pages)).FullName
$pageFiles = Get-ChildItem -Path $sourceRoot -Filter *.txt -Recurse
$pageMap = @{}
$pageCount = 0
foreach ($pagePath in $pageFiles)
{
    $sourceFullPath = $pagePath.FullName
    $sourceFilename = Split-Path -Path $sourceFullPath -Leaf
    $sourceParent = Split-Path -Path $sourceFullPath -Parent
    $intermediatePath = $sourceParent.Replace("$sourceRoot\", '')
    $dokuWikiPath = $intermediatePath.Replace('\', ':')
    if ($sourceFilename -ne 'start.txt')
    {
        $dokuWikiPath += ':' + $sourceFilename.Replace('.txt', '')
    }

    $dokuWikiPath = $dokuWikiPath.Replace('_', ' ')
    $mdPath = '/' + (($dokuWikiPath -split ':' | ForEach-Object { ConvertFrom-DokuWikiPath -Path $_ }) -join '/')
    if ($RootName)
    {
        $mdPath = "/$RootName$mdPath"
    }

    $pageMap.$dokuWikiPath = $mdPath
    $pageCount++
}

$global:pageMap = $pageMap

Write-Host "Mapped $pageCount pages"

Write-Host "Converting pages"
$namespaces = @()
$pageCount = 0
foreach ($pagePath in $pageFiles)
{
    $sourceFullPath = $pagePath.FullName
    $sourceFilename = Split-Path -Path $sourceFullPath -Leaf
    $sourceParent = Split-Path -Path $sourceFullPath -Parent
    $intermediatePath = $sourceParent.Replace($sourceRoot, '')
    $namespace = $intermediatePath.Replace('\', ':')
    $intermediatePath = ($intermediatePath -split '\\' | ForEach-Object { ConvertFrom-DokuWikiPath -Path $_ }) -join '\'
    if ($namespaces -notcontains $namespace)
    {
        $namespaces += $namespace
    }

    if ($sourceFilename -eq 'start.txt')
    {
        if ($intermediatePath)
        {
            $parent = "$mdDestination\$intermediatePath"
        }
        else
        {
            $parent = $mdDestination
        }

        $pageName = Split-Path -Path $parent -Leaf
        $intermediateParent = Split-Path -Path $parent -Parent
        $destinationPath = "$intermediateParent\$pageName`.md"
    }
    else
    {
        $pageName = $sourceFilename.Replace('.txt', '')
        $pageName = ConvertFrom-DokuWikiPath -Path $pageName
        $destinationPath = "$mdDestination\$intermediatePath\$pageName`.md"
    }

    $page = @{
        Name = $pageName
        Path = $sourceFullPath
        Namespace = $namespace
        Destination = $destinationPath
    }

    $destinationParent = Split-Path -Path $destinationPath -Parent
    if (-not (Test-Path -Path $destinationParent -PathType Container))
    {
        New-Item -Path $destinationParent -ItemType Container | Out-Null
    }
    
    & $PSScriptRoot\Convert-DokuWikiPage.ps1 @page -AttachmentMapPath $AttachmentMapPath -PageMap $pageMap | Set-Content -Path $destinationPath -Encoding UTF8
    $pageCount++
}

Write-Host "Converted $pageCount pages."
