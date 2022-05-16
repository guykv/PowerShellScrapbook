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
    $Destination
)

function Convert-DokuWikiLinks
{
    param (
        [string]$Markup
    )

    $pattern = '\[\[([^\|]+)(?:\|([^\]]+))?\]\]'
    foreach ($match in [regex]::Matches($Markup, $pattern))
    {
        $link = $match.Groups[1].Value
        $text = $match.Groups[2].Value
        if ($link -match '^https?://')
        {
            $replacement = "[$text]($link)"
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
    '\[\[\\\\.*\]\]'
    '\(\(.*\)\)'
    '~~NOTOC~~'
    '{{ '
    ' }}'
    '{{.*\|.*}}'
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
        Replace = '==== (.*) ===='
        With = '## $1'
    }
    @{
        Replace = '=== (.*) ==='
        With = '### $1'
    }
    @{
        Replace = '== (.*) =='
        With = '#### $1'
    }
    @{
        Replace = '= (.*) ='
        With = '##### $1'
    }
    @{
        Replace = '^----$'
        With = '---'
    }
)

$inMarkup = $true
$lineNumber = 0
foreach ($line in (Get-Content -Path $Path -Encoding UTF8))
{
    $converted = $line.Trim()
    $lineNumber++
    if ($inMarkup)
    {
        foreach ($w in $WarningPatterns)
        {
            if ($converted -match $w)
            {
                Write-Warning "The markup in $Path line $lineNumber contains an unsupported DokuWiki construct ($w)"
            }
        }
    
        foreach ($r in $SimpleReplacements)
        {
            $converted = $converted -replace $r.Replace, $r.With
        }
    
        $converted = Convert-DokuWikiLinks -Markup $converted
        $converted = Convert-DokuWikiTableHeader -Markup $converted
    }

    $converted
}
