Function Get-InstalledFrameworks
{
    <#
        .SYNOPSIS
        Detects which version(s) of .NET Framework that are present on this system.
        .DESCRIPTION
        Uses the methods described in http://support.microsoft.com/kb/315291 and
        http://msdn.microsoft.com/en-us/library/hh925568(v=vs.110).aspx#net_b to determine
        installed versions of .NET Framework. Detects versions 1.0, 1.1, 2.0, 3.0,
        3.5, 4.0, 4.5, 4.5.1, 4.5.2
    #>
    $oldPath = "HKLM:\Software\Microsoft\.NETFramework\Policy"
    $path = "HKLM:\Software\Microsoft\Net Framework Setup\NDP"
    @(
        @{
            Path = "$oldPath\v1.0"
            Name = "3705"
            Value = "3321-3705"
            Version = "1.0"
        },
        @{
            Path = "$oldPath\v1.1"
            Name = "4322"
            Value = "3706-4322"
            Version = "1.1"
        },
        @{
            Path = "$oldPath\v2.0"
            Name = "50727"
            Value = "50727-50727"
            Version = "2.0"
        },
        @{
            Path = "$path\v3.0\Setup"
            Name = "InstallSuccess"
            Value = "1"
            Version = "3.0"
        },
        @{
            Path = "$path\v3.5"
            Name = "Install"
            Value = "1"
            Version = "3.5"
        },
        @{
            Path = "$path\v4\Client"
            Name = "Install"
            Value = "1"
            Version = "4.0c"
        },
        @{
            Path = "$path\v4\Full"
            Name = "Install"
            Value = "1"
            Version = "4.0"
        },
        @{
            Path = "$path\v4\Full"
            Name = "Release"
            Value = "378389"
            Version = "4.5"
        },
        @{
            Path = "$path\v4\Full"
            Name = "Release"
            Value = "378675"
            Version = "4.5.1"
        },
        @{
            Path = "$path\v4\Full"
            Name = "Release"
            Value = "378758"
            Version = "4.5.1"
        },
        @{
            Path = "$path\v4\Full"
            Name = "Release"
            Value = "379893"
            Version = "4.5.2"
        }
    ) | Where-Object -FilterScript {
        $reg = Get-ItemProperty -Path $_.Path -Name $_.Name -ErrorAction SilentlyContinue
        if ($reg)
        {
            $_.Value -eq $reg.$($_.Name)
        }
    } | ForEach-Object -Process {
        $_.Version
    }
}