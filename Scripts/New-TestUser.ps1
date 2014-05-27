[CmdletBinding(SupportsShouldProcess = $true)]
Param
(
    [Parameter()]
    [int]$Count = 1,

    [Parameter()]
    [string]$Container,

    [Parameter()]
    [string[]]$Groups,

    [Parameter()]
    [string]$Password = "Password01",

    [Parameter()]
    [string]$Prefix = "testuser",

    [Parameter()]
    [string]$GivenName = "Test",

    [Parameter()]
    [string]$SurnamePrefix = "User",

    [Parameter()]
    [string]$Title = "Test User",

    [Parameter()]
    [string]$Department = "Testing Department",

    [Parameter()]
    [string]$Company = "Test Company",

    [Parameter()]
    [string]$Description = "User account for testing purposes",

    [Parameter()]
    [bool]$ChangePasswordAtLogon = $true,

    [Parameter()]
    [bool]$PasswordNeverExpires = $false,

    [Parameter()]
    [string]$Domain,

    [Parameter()]
    [string]$UPNSuffix,

    [Parameter()]
    [switch]$PassThru
)

Import-Module -Name ActiveDirectory -ErrorAction Stop

if ($Domain)
{
    $actualDomain = Get-ADDomain -Identity $Domain -ErrorAction Stop
}
else
{
    $actualDomain = Get-ADDomain -ErrorAction Stop
}

if ($UPNSuffix)
{
    $actualUPNSuffix = $UPNSuffix
}
else
{
    $actualUPNSuffix = $actualDomain.DNSRoot
}

if ($Container)
{
    $actualContainer = $Container
}
else
{
    $actualContainer = $actualDomain.UsersContainer
    if (-not $actualContainer)
    {
        throw "No container"
    }
}

if ($Groups)
{
    $actualGroups = @()
    foreach ($g in $Groups)
    {
        $actualGroups += Get-ADGroup -Identity $g -ErrorAction Stop
    }
}

$suffix = 0
for ($i = 0; $i -lt $Count; $i++)
{
    $suffix++
    $sam = $Prefix + $suffix
    $upn = $sam + "@" + $actualUPNSuffix
    while (Get-ADObject -Filter { SAMAccountName -eq $sam -or Name -eq $sam -or UserPrincipalName -eq $upn })
    {
        $suffix++
        $sam = $Prefix + $suffix
        $upn = $sam + "@" + $actualUPNSuffix
    }

    $params = @{
        Path = $actualContainer
        SamAccountName = $sam
        Name = $sam
        UserPrincipalName = $upn
        GivenName = $GivenName
        Surname = "$SurnamePrefix$suffix"
        DisplayName = "$GivenName $SurnamePrefix$suffix"
        Title = $Title
        Department = $Department
        Company = $Company
        Description = $Description
        AccountPassword = ConvertTo-SecureString $Password -AsPlainText -Force
        ChangePasswordAtLogon = $ChangePasswordAtLogon
        PasswordNeverExpires = $PasswordNeverExpires
        Enabled = $true
    }

    $user = New-ADUser @params -PassThru
    if ($user -and $actualGroups)
    {
        foreach ($g in $actualGroups)
        {
            Add-ADGroupMember -Identity $g -Members $user
        }
    }

    if ($PassThru)
    {
        $user
    }
}
