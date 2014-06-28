<#
    .SYNOPSIS
    Updates README.md
    .DESCRIPTION
    This script extracts information from the script files to generate
    a simple markdown table of all the scripts.
    .PARAMETER ConsoleOnly
    If specified, the output is rendered on the console rather than into
    the readme file.
#>
Param
(
    [Parameter()]
    [switch]$ConsoleOnly
)

$CONST = Data {
    @{
        TOPTEXT = @"
PowerShellScrapbook
====================

This is simply a repository of PowerShell functions and scripts that might sometime
in the future become handy once more.

###Overview

"@

        FILENAME = "README.md"
    }
}

Function Get-PowerShellHelpCommentBlock
{
    Param
    (
        [Parameter()]
        [string]$Path,

        [Parameter()]
        [string]$Keyword,

        [Parameter()]
        [switch]$KeepKeywordLine
    )

    $eating = $false
    $capturedLines = @()
    foreach ($line in (Get-Content -Path $Path))
    {
        if ($eating)
        {
            if ($line -match "^\s*\." -or $line -match "#>")
            {
                break
            }

            $capturedLines += $line
        }

        if ($line -match $Keyword)
        {
            $eating = $true
            if ($KeepKeywordLine)
            {
                $capturedLines += $line
            }
        }
    }

    $capturedLines
}

Function Format-MarkdownTable
{
    Param
    (
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$InputObject,

        [Parameter()]
        [string[]]$Properties
    )

    Begin
    {
        $maxWidths = @()
        $allRows = @()
        if ($Properties)
        {
            $header = $Properties
            $maxWidths = @(0) * $header.Length
            $allRows += ,$header
        }
    }

    Process
    {
        if (-not $header)
        {
            $header = @()
            foreach ($p in Get-Member -InputObject $InputObject -MemberType Property,NoteProperty)
            {
                $header += $p.Name
                $maxWidths += 0
            }

            $allRows += ,$header
        }

        $row = @()
        for ($i = 0; $i -lt $header.Length; $i++)
        {
            [string]$value = $InputObject.$($header[$i])
            $maxWidths[$i] = [Math]::Max($maxWidths[$i], $value.Length)
            $row += $value
        }

        $allRows += ,$row
    }

    End
    {
        $firstRow = $true
        foreach ($r in $allRows)
        {
            $cells = @()
            for ($i = 0; $i -lt $header.Length; $i++)
            {
                if ($r[$i])
                {
                    $cells += $r[$i].PadRight($maxWidths[$i], " ")
                }
                else
                {
                    $cells += New-Object String(" ", $maxWidths[$i])
                }
            }

            $row = $cells -join " | "
            Write-Output -InputObject $row

            if ($firstRow)
            {
                $cells = @()
                for ($i = 0; $i -lt $header.Length; $i++)
                {
                    $cells += New-Object String("-", $maxWidths[$i])
                }

                $row = $cells -join " | "
                Write-Output -InputObject $row
                $firstRow = $false
            }
        }
    }
}

$rows = @()
'Scripts', 'Functions' | foreach {
    $type = $_ -replace "s$", ""
    Get-ChildItem -Path "$PSScriptRoot\$_" | foreach {
        $synopsis = (Get-PowerShellHelpCommentBlock -Path $_.FullName -Keyword ".SYNOPSIS" | %{ $_.Trim() }) -join " "
        $rows += New-Object -TypeName PSObject -Property @{
            Name = $_.Name
            Type = $type
            Synopsis = $synopsis
        }
    }
}

$text = $CONST.TOPTEXT
$text += ($rows | Sort-Object -Property Name | Format-MarkdownTable -Properties Name,Type,Synopsis | Out-String)

if ($ConsoleOnly)
{
    Write-Host $text
}
else
{
    Set-Content -Value $text -Path $CONST.FILENAME
}
