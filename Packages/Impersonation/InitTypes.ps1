#requires -version 2.0

foreach ($source in (Get-ChildItem $PSScriptRoot\Types -Filter *.cs))
{
	$timestampVarName = "CustomTypeTimestamp-$($source.Name.Replace(".", "_"))"
	$ts = Get-Variable -Name $timestampVarName -Scope Global -ValueOnly -ErrorAction SilentlyContinue
	if ($ts)
	{
		if ($ts -ne $source.LastWriteTime)
		{
			Write-Warning "The type(s) defined by the source code in $($source.FullName) has a different timestamp ($ts) than the file timestamp ($($source.LastWriteTime)). This might indicate that the source has been changed. It is recommended that you start a new PowerShell session and re-import the module."
		}
	}
	else
	{
		$code = Get-Content $source.PSPath | Out-String
		$types = Add-Type -TypeDefinition $code -Language CSharp -PassThru
		if ($?)
		{
			$types | ForEach-Object {
				Write-Verbose "Added type: $($_FullName)"
			}
			
			Set-Variable -Name $timestampVarName -Scope Global -Value $source.LastWriteTime
		}
	}
}
