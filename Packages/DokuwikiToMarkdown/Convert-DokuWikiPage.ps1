[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]
    $Path,

    [string]
    $Name,

    [string]
    $Namespace,

    [Parameter(Mandatory=$true)]
    [string]
    $Destination,

    [Parameter(Mandatory=$true)]
    $AttachmentMapPath,

    [Parameter()]
    [string]
    $Newline = "`r`n"
)

$WarningPatterns = @(
    '\[\[.*?>.*?\]\]'
    '\(\(.*?\)\)'
    '~~NOTOC~~'
    '<nowiki>'
    '%%'
    '<file>'
    '<html>(?!<br></html>)'
    '<php>'
)

$SimpleReplacements = @(
    @{
        Replace = '\/\/([^/]*)\/\/'
        With = '*$1*'
    }
    @{
        Replace = '__([^_]*)__'
        With = '<u>$1</u>'
    }
    @{
        Replace = "''(.*)''"
        With = '`$1`'
    }
    @{
        Replace = '<del>(.*)</del>'
        With = '~~$1~~'
    }
    @{
        Replace = '\\\\ '
        With = '<br/>'
    }
    @{
        Replace = '=====* (.*) =====*'
        With = '# $1'
    }
    @{
        Replace = '==== (.*) ====*'
        With = '## $1'
    }
    @{
        Replace = '=== (.*) ===*'
        With = '### $1'
    }
    @{
        Replace = '== (.*) ==*'
        With = '#### $1'
    }
    @{
        Replace = '= (.*) =*'
        With = '##### $1'
    }
    @{
        Replace = '^----$'
        With = '---'
    }
    @{
        Replace = '^  - '
        With = '1. '
    }
    @{
        Replace = '<html><br></html>'
        With = '<br/>'
    }
    @{
        Replace = '<code>(.*?)<\/code>'
        With = '`$1`'
    }
    @{
        Replace = '<code ([^<]+)>(.*?)<\/code>'
        With = $Newline + '```$1' + $Newline + '$2' + $Newline + '```' + $Newline
    }
)

. $PSScriptRoot\Functions.ps1

function Convert-MediaLinks
{
    param (
        [string]$Markup,

        [Hashtable]$AttachmentMap,

        [string]$SourceReference
    )

    $pattern = '{{ ?:?([^?]+?)(?:\??([\dx]+|linkonly))?(:?\|([^}]*))? ?}}'
    foreach ($match in [regex]::Matches($Markup, $pattern))
    {
        $fullMatch = $match.Groups[0].Value
        $dokuWikiPath = $match.Groups[1].Value.Trim()
        $spec = $match.Groups[2].Value
        $caption = $match.Groups[4].Value

        if ($fullMatch -match '^{{ | }}$')
        {
            Write-Warning "Media horizontal alignment not supported ('{{ ' or ' }}'): $SourceReference"
        }

        if (-not $AttachmentMap.ContainsKey($dokuWikiPath))
        {
            Write-Warning "Unmapped attachment $($dokuWikiPath): $SourceReference"
            continue
        }

        $mapping = $AttachmentMap.$dokuWikiPath
        $mdPath = $mapping.MdPath
        $name = $mapping.Name

        if ($mapping.IsImage -and $caption)
        {
            Write-Warning "Image caption not supported: $SourceReference"
        }

        if ($spec -eq 'linkonly')
        {
            $replacement = "[$name]($mdPath)"
        }
        else
        {
            if ($spec)
            {
                if ($spec -match '^\d+$')
                {
                    $spec += 'x'
                }
                
                $spec = " =$spec"
            }

            if ($mapping.IsImage)
            {
                $replacement = "![$name]($mdPath$spec)"
            }
            else
            {
                if ($caption)
                {
                    $replacement = "[$caption]($mdPath$spec)"
                }
                else
                {
                    $replacement = "[$name]($mdPath$spec)"
                }
            }

        }

        $converted = $converted.Replace($match.Value, $replacement)
    }

    $converted
}

function Convert-DokuWikiLinks
{
    param (
        [string]$Markup
    )

    $pattern = '\[\[:?([^\|]+)(?:\|([^\]]+))?\]\]'
    foreach ($match in [regex]::Matches($Markup, $pattern))
    {
        $link = $match.Groups[1].Value
        $text = $match.Groups[2].Value
        if (-not $text)
        {
            if ($link.EndsWith(':start'))
            {
                $text = ($link -split ":")[-2]
            }
            else
            {
                $text = ($link -split ":")[-1]
            }
        }

        if ($link -match '^https?://')
        {
            $replacement = "[$text]($link)"
        }
        elseif ($link -match '^\\\\')
        {
            $link = $link -replace '\\', '/'
            if (-not $text)
            {
                $text = $link
            }

            $href = "file:///$link"
            $replacement = "<a href=`"$href`">$text</a>"
        }
        else
        {
            $page = $link.Replace(':', '/').Replace(' ', '-')
            $replacement = "[$text](/$page)"
        }

        $converted = $converted.Replace($match.Value, $replacement)
    }

    $converted
}

function Convert-DokuWikiTableHeader
{
    param (
        [string]$Markup
    )

    if ($Markup -match '^\s*\^')
    {
        $Markup.Replace('^', '|')
        $sep = $Markup -replace '\^[^\^]*', '|---'
        $sep = $sep -replace '---$', ''
        $sep
    }
    else
    {
        $Markup
    }
}

$attachmentMap = Read-AttachmentMap -AttachmentMapPath $AttachmentMapPath -Required
$inMarkup = $true
$lineNumber = 0
foreach ($line in (Get-Content -Path $Path -Encoding UTF8))
{
    $converted = $line.TrimEnd()
    $lineNumber++
    $sourceReference = "$Path`:$lineNumber"
    if ($inMarkup)
    {
        foreach ($w in $WarningPatterns)
        {
            if ($converted -match $w)
            {
                Write-Warning "The markup contains an unsupported DokuWiki construct ($w): $sourceReference"
            }
        }
    
        foreach ($r in $SimpleReplacements)
        {
            $converted = $converted -replace $r.Replace, $r.With
        }
    
        $converted = Convert-DokuWikiLinks -Markup $converted
        $converted = Convert-DokuWikiTableHeader -Markup $converted
        $converted = Convert-MediaLinks -Markup $converted -AttachmentMap $attachmentMap -SourceReference $sourceReference
    }

    if ($converted -match '^(.*?)<code(?: ([^>]+))?>(.*)$')
    {
        $converted = $Matches.1 + $Newline + '```' + $Matches.2 + $Newline + $Matches.3
        $inMarkup = $false
    }

    if (-not $inMarkup -and $converted -match '^(.*?)<\/code>(.*)$')
    {
        $converted = $Matches.1 + $Newline + '```' + $Newline + $Matches.2
        $inMarkup = $true
    }

    $converted
}
