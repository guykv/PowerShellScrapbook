[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]
    $Path,

    [Parameter(Mandatory=$true)]
    [string]
    $Destination
)

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

$pageRoot = Join-Path -Path $Path -ChildPath pages
$namespaces = @()
foreach ($pagePath in (Get-ChildItem -Path $pageRoot -Filter *.txt -Recurse))
{
    $fullPath = $pagePath.FullName
    $filename = Split-Path -Path $fullPath -Leaf
    $parent = Split-Path -Path $fullPath -Parent
    $intermediatePath = $parent.Replace($pageRoot + "\", '')
    $namespace = $intermediatePath.Replace('\', ':')
    if ($namespaces -notcontains $namespace)
    {
        $namespaces += $namespace
    }

    $name = ConvertFrom-DokuWikiPageName -Name ($filename.Replace('.txt', ''))
    $page = @{
        Name = $name
        Path = $fullPath
        Namespace = $namespace
        Destination = "$Destination\$intermediatePath\$name`.md"
    }

    & $PSScriptRoot\Convert-DokuWikiPage.ps1 @page
    throw 'test'
}
