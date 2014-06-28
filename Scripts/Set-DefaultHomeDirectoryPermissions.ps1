<#
    .Synopsis
    Sets default permissions and ownership to a user's home directory
    .Description
    This script resets all permissions on the specified directory
    to conform to a common best practice set of permissions. The
    permissions look like this:

    BUILTIN\Administrators - Full Control
    NT AUTHORITY\SYSTEM - Full Control
    User - Modify

    In able to make sure the script can reset all permissions,
    ownership is reset too, first on all files and directories to
    the administrators group recursively, then back to the user
    (all directories and files except the root directory).

    Note: The script requires subinacl.exe, a low-level NTFS
    metadata tool that can be downloaded from Microsoft.
    .Parameter Path
    The full path of the home directory
    .Parameter NoInherit
    Whether to cut off inheritance from the parent directory
    .Parameter IgnoreMissingUser
    Whether to continue setting permissions even though no user
    with the corresponding user name exists. This will result in
    a home directory to which no normal user has access, but
    the Administrator group and SYSTEM will be given full control.
    This is useful if the permissions are set in a way that
    denies admins access.
    .Notes
    Author: Guy Kvaernberg <me@guyk.no>
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
Param
(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string[]]$Path,
    
    [Parameter()]
    [switch]$NoInherit,
    
    [Parameter()]
    [switch]$IgnoreMissingUser,

    [Parameter()]
    [string]$SubinaclPath = ".\subinacl.exe"
)

Begin
{
    Import-Module -Name ActiveDirectory -ErrorAction Stop
    
    Function Add-DefaultHomeAce
    {
        Param
        (
            [Security.AccessControl.DirectorySecurity]$Acl,
            
            $Id,
            
            [Security.AccessControl.FileSystemRights]$Rights
        )
        
        $args = @(
            $Id,
            $Rights,
            'ContainerInherit,ObjectInherit',
            'None',
            'Allow'
        )
        
        $rule = New-Object -TypeName Security.AccessControl.FileSystemAccessRule -ArgumentList $args
        $Acl.AddAccessRule($rule)
    }
}

Process
{
    foreach ($p in $Path)
    {
        if (-not (Test-Path -Path $p))
        {
            Write-Warning "$p`: doesn't exist"
            continue
        }
        
        $acl = New-Object Security.AccessControl.DirectorySecurity
        if ($NoInherit)
        {
            $acl.SetAccessRuleProtection($true, $false)
        }
        
        Add-DefaultHomeAce -Acl $acl -Id "NT AUTHORITY\SYSTEM" -Rights 'FullControl'
        Add-DefaultHomeAce -Acl $acl -Id "BUILTIN\Administrators" -Rights 'FullControl'
        
        Write-Verbose -Message "$p`: Starting"
        $item = Get-Item -Path $p
        
        $sam = $item.Name
        Write-Verbose -Message "$p`: User name: '$sam'"
        $user = Get-ADUser -Filter { SAMAccountName -eq $sam } -ErrorAction SilentlyContinue
        if ($user)
        {
            Add-DefaultHomeAce -Acl $acl -Id $user.SID -Rights 'Modify'
        }
        else
        {
            Write-Warning "$p`: The user '$sam' doesn't exist"
            if (-not $IgnoreMissingUser)
            {
                continue
            }
        }
        
        Write-Verbose -Message "$p`: Resetting ownership"
        if ($PSCmdlet.ShouldProcess($p, "Reset ownership to Administrators group"))
        {
            & $SubinaclPath /noverbose /file $item.FullName /setowner=Administrators
        }
        
        if (-not $?)
        {
            throw "$p`: subinacl error"
        }
        
        if ($PSCmdlet.ShouldProcess("$p\*.*", "Reset ownership to Administrators group"))
        {
            & $SubinaclPath /noverbose /subdirectories "$($item.FullName)\*.*" /setowner=Administrators
        }
        
        if (-not $?)
        {
            throw "$p`: subinacl error"
        }

        Write-Verbose -Message "$p`: Setting permissions on root folder"
        Set-Acl -Path $p -AclObject $acl -WhatIf:$WhatIfPreference
        
        if ($user)
        {
            $acl = New-Object Security.AccessControl.DirectorySecurity
            $acl.SetOwner($user.SID)
            Write-Verbose -Message "$p`: Setting permissions on child objects"
            Get-ChildItem -Recurse -Path $p -ErrorAction Stop | ForEach-Object -Process {
                Set-Acl -Path $_.FullName -AclObject $acl -WhatIf:$WhatIfPreference
            }
        }
    }
}
