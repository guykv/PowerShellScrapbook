Function Get-FileHash
{
    <#
        .SYNOPSIS
        Calculates a hash from the contents of a file
        .DESCRIPTION
        .PARAMETER ErrorMessage
    #>
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [string[]]$Path,

        [Parameter()]
        [ValidateSet('MD5', 'SHA1', 'SHA256')]
        [string]$HashType = 'MD5'
    )

    Begin
    {
        switch ($HashType)
        {
            'MD5'
            {
                $hasher = [System.Security.Cryptography.MD5]::Create()
            }


            'SHA1'
            {
                $hasher = [System.Security.Cryptography.SHA1]::Create()
            }

            'SHA256'
            {
                $hasher = [System.Security.Cryptography.SHA256]::Create()
            }
        }
    }

    Process
    {
        foreach ($p in $Path)
        {
            if (Test-Path -Path $p)
            {
                $stream = New-Object System.IO.StreamReader($p)
                $result = $hasher.ComputeHash($stream.BaseStream)
                $stream.Close()

                $sb = New-Object System.Text.StringBuilder
                foreach ($c in $result)
                {
                    [void]$sb.Append($_.ToString("x2"))
                }

                [PSCustomObject]@{
                    Path = $p
                    Hash = $sb.ToString()
                    HashType = $HashType
                }

            }
            else
            {
                Write-Warning "The file '$p' couldn't be opened"
            }
        }
    }
}
