﻿<#
    .Synopsis
    Creates any number of test users in Active Directory with common characteristics
    .Description
    This script can be used to bulk create test users in Active Directory, which can be
    handy when stress testing an environment or preparing for a large number of testers.
    .Parameter Count
    Number of test users
    .Parameter Container
    Active Directory container in which to create the test users. Defaults to the built-in
    Users container.
    .Parameter Groups
    One or more groups into which to add the test users
    .Parameter Password
    All the test users are given the same password. Defaults to 'Password01'.
    .Parameter Prefix
    Prefix for the user names of the test users. The user names are generated by appending
    a number. Defaults to 'testuser'.
    .Parameter GivenName
    First name of the test users, defaults to 'Test'.
    .Parameter SurnamePrefix
    Prefix for the last name of the test users. A number is added to keep the names
    pseudo-unique. Defaults to 'User'.
    .Parameter Title
    Test user title, defaults to 'Test User'.
    .Parameter Department
    Test user department, defaults to 'Testing Department'.
    .Parameter Company
    Test user company, defaults to 'Test Company'.
    .Parameter Description
    Test user description, defaults to 'User account for testing purposes'.
    .Parameter ChangePasswordAtLogon
    Whether to force the users to change passwords at first logon. Default
    value is $true.
    .Parameter PasswordNeverExpires
    Whether the given password never expires. Default value is $false.
    .Parameter Domain
    Domain in which to create the users. Defaults to the domain in which
    the current computer is a member.
    .Parameter UPNSuffix
    Suffix to use when generating the userPrincipalName attribute for the
    users. Defaults to @[domain.dns.name].
    .Parameter PassThru
    Whether to output the user objects as they are created.
    .Notes
    Author: Guy Kvaernberg <me@guyk.no>
#>
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
