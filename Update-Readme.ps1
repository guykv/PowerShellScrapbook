<#
    .Synopsis
    Updates README.md
    .Description
    This script extracts 
#>


$CONSTANTS = Data {
    @{
        TopText = @"
psfunc
======

My reusable PowerShell functions

This is simply a repository of PowerShell functions that might sometime
in the future become handy once more.
"@

        Filename = "README.md"
    }
}

$text = $CONSTANTS.TopText

foreach ($f in (Get-ChildItem -Path . -Filter "*.ps1"))
{
    $synopsis = Get-Help -Name $f.FullName -
}
