Function ConvertTo-SafeChars
{
    <#
        .SYNOPSIS
        Converts a string into "safe" characters
        .DESCRIPTION
        Uses a substitution table to change international latin characters like æ,ø,å
        into readable ascii-128 equivalents, and removes any non-letter characters
        .PARAMETER InputString
        String to convert
        .PARAMETER PreserveChars
        Non-letter characters that is to be preserved
    #>
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$InputString,

        [Parameter()]
        [string]$PreserveChars
    )

    Begin
    {
        $substitutions = Data {
            @{
                la = 'æåáàãäâ'
                le = 'éèëê'
                li = 'íìïî'
                lo = 'øóòõô'
                lu = 'úùüû'
                ly = 'ýÿ'
                ln = 'ñ'
                lc = 'ç'
                lss = 'ß'
                uA = 'ÆÅÁÀÃÄÂ'
                uE = 'ÉÈËÊ'
                uI = 'ÍÌÏÎ'
                uO = 'ØÓÒÕÔ'
                uU = 'ÚÙÜÛ'
                uY = 'ÝŸ'
                uN = 'Ñ'
                uC = 'Ç'
            }
        }
    }

    Process
    {
        foreach ($s in $InputString)
        {
            $ret = $s
            foreach ($s in $substitutions.GetEnumerator())
            {
                $ret = $ret -creplace "[$($s.Value)]", $s.Name.Substring(1)
            }

            $ret -replace "[^a-zA-Z$PreserveChars]", ""
        }
    }
}
