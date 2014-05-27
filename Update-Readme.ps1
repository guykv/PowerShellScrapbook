<#
    .Synopsis
    Updates README.md
    .Description
    This script extracts information from the 
#>


$CONSTANTS = Data {
    @{
        TopText = @"
PowerShellRecycleBin
====================

This is simply a repository of PowerShell functions and scripts that might sometime
in the future become handy once more.

"@

        FileName = "README.md"
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
                Write-Output -InputObject (New-Object String("-", $row.Length))
                $firstRow = $false
            }
        }
    }
}

$text = $CONSTANTS.TopText

$rows = @()
foreach ($f in (Get-ChildItem -Path "$PSScriptRoot\Scripts" -Filter "*.ps1"))
{
    $synopsis = (Get-PowerShellHelpCommentBlock -Path $f.FullName -Keyword ".SYNOPSIS" | %{ $_.Trim() }) -join " "
    $rows += New-Object -TypeName PSObject -Property @{
        Name = "Scripts\" + $f.Name
        Synopsis = $synopsis
    }
}

$CONSTANTS.TopText | Set-Content -Path $CONSTANTS.FileName
$rows | Format-MarkdownTable | Add-Content -Path $CONSTANTS.FileName
