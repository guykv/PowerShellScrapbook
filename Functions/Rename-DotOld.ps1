Function Rename-DotOld
{
    <#
        .SYNOPSIS
        Renames a file or folder to <originalname>.old
        .DESCRIPTION
        Adds the suffix '.old' to a file or folder. If this name is taken
        (by invoking this function multiple time for instance), a number
        is added.
        .PARAMETER Path
        The path to the file or folder to be renamed
    #>
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $item = Get-Item -Path $Path -ErrorAction Stop
    $suffix = ""
    while (Test-Path -Path ($item.PSParentPath + ($newName = $item.Name + ".old$suffix")))
    {
        $suffix = [int]$suffix + 1;
    }

    Rename-Item -Path $item.FullName -NewName $newName -ErrorAction Stop
}