Function New-RandomPassword
{
    <#
        .Synopsis
        Generate a random password.
        .Description
        Generates a random password using crypto services in the .NET Framework,
        taking care to avoid the modulo bias.
        .Parameter Length
        How many characters wide the password shall be. Default value is 16.
        .Parameter Complexity
        How many character classes that will be included in the password.
        .Parameter CharacterClasses
        An array of different character classes with which to build the passwords.
        .Example
        PS C:\>$secret = New-Password 24
        
        Generates a high-complexity password of 24 characters.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter()]
		[ValidateRange(4, 65535)]
		[byte]$Length = 16,

        [Parameter()]
        [string[]]$CharacterClasses = (
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
            'abcdefghijklmnopqrstuvwxyz',
            '1234567890',
            '*$-+?_&=!%'
        ),
		
        [Parameter()]
		[int]$Complexity = 4
    )
    
    Begin
    {
        if ($Complexity -lt 1 -or $Complexity -gt $CharacterClasses.Length)
        {
            throw "Illegal complexity"
        }

        # Crypto seed, unaffected by system clock
        $randomBytes = New-Object byte[] 4
        $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $rng.GetBytes($randomBytes) | Out-Null
        $seed = [BitConverter]::ToInt32($randomBytes, 0)
        $random = New-Object Random $seed
        
        $charGroups = @()
        for ($i = 0; $i -lt $Complexity; $i++)
        {
            $charGroups += $CharacterClasses[$i]
        }
        
        # Corrects for modulo bias to create a truly random value
        # between $min and $max - 1.
        function Get-TrueRandomInterval
        {
            param ($min, $max)
            
            $realMax = $max - $min
            $maxRnd = [Int32]::MaxValue - ([Int32]::MaxValue % $realMax)
            while (($r = $random.Next()) -ge $maxRnd) {}
            ($r % $realMax) + $min
        }
        
        # Implements the Knuth-Fisher-Yates shuffle
        function Get-ShuffledSequence
        {
            param ($sequence)
            
            $newSequence = $sequence.ToCharArray()
            for ($i = $newSequence.Length - 1; $i -gt 0; $i--)
            {
                $newPos = Get-TrueRandomInterval 0 $i
                $tmp = $newSequence[$i]
                $newSequence[$i] = $newSequence[$newPos]
                $newSequence[$newPos] = $tmp
            }
            
            New-Object String(,$newSequence)
        }
    }
    
    Process
    {
        # Distribute characters evenly among the character groups
        $charsPerGroup = [Math]::Floor($Length / $charGroups.Length)
        $numFromEachGroup = @($charsPerGroup) * $charGroups.Length
        
        # Distribute the remainder randomly
        $remainingChars = $Length % $charGroups.Length
        for ($i = 0; $i -lt $remainingChars; $i++)
        {
            $numFromEachGroup[(Get-TrueRandomInterval 0 $numFromEachGroup.Length)] += 1
        }
        
        # Generate a random sequence from each character group
        for ($i = 0; $i -lt $numFromEachGroup.Length; $i++)
        {
            for ($j = 0; $j -lt $numFromEachGroup[$i]; $j++)
            {
                $characters += $charGroups[$i][(Get-TrueRandomInterval 0 ($charGroups[$i].Length))]
            }
        }
        
        # Shuffle the sequence
        Get-ShuffledSequence $characters
    }
}