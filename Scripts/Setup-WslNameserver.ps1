$ErrorActionPreference = 'Stop'
 
$rule = Get-DnsClientNrptRule | Where-Object { $_.Namespace -eq '.docker.localhost' }
$ip = [string](& wsl.exe hostname -I).Trim()
 
if ($rule)
{
    $rule | Set-DnsClientNrptRule -Namespace '.docker.localhost' -NameServers $ip -DisplayName "WSL nameserver"
}
else
{
    Add-DnsClientNrptRule -Namespace '.docker.localhost' -NameServers $ip -DisplayName "WSL nameserver"
}