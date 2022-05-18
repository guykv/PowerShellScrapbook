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

    [Parameter()]
    [string]
    $Newline = "`r`n"
)

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
            $page = $link.Replace(':', '/')
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

$WarningPatterns = @(
    '\[\[.*>.*\]\]'
    '\(\(.*\)\)'
    '~~NOTOC~~'
    '{{ '
    ' }}'
    '<nowiki>'
    '%%'
    '<file>'
    '<html>'
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

$inMarkup = $true
$lineNumber = 0
foreach ($line in (Get-Content -Path $Path -Encoding UTF8))
{
    $converted = $line.TrimEnd()
    $lineNumber++
    if ($inMarkup)
    {
        foreach ($r in $SimpleReplacements)
        {
            $converted = $converted -replace $r.Replace, $r.With
        }
    
        foreach ($w in $WarningPatterns)
        {
            if ($converted -match $w)
            {
                Write-Warning "The markup in $Path line $lineNumber contains an unsupported DokuWiki construct ($w)"
            }
        }
    
        $converted = Convert-DokuWikiLinks -Markup $converted
        $converted = Convert-DokuWikiTableHeader -Markup $converted
    }

    if ($converted -match '^(.*?)<code(?: ([^>]+))?>(.*)$')
    {
        $converted = $Matches.1 + $Newline + '```' + $Matches.2 + $Newline + $Matches.3
        $inMarkup = $false
    }

    if (-not $inMarkup -and $converted -match '^(.*?)<\/code>(.*)$')
    {
        Write-Warning $lineNumber
        $converted = $Matches.1 + $Newline + '```' + $Newline + $Matches.2
        $inMarkup = $true
    }

    $converted
}
