
function Get-PRETemplate{

    <#

        .SYNOPSIS
        Enter the synopsis of this function

        .DESCRIPTION
        Enter the description of this function

        .PARAMETER Param1
        Enter the description of the Param1

        .EXAMPLE
        Get-SomeSettings.ps1 -Param1 'run'

        .NOTES
        Date, Author, Version, Notes

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    begin{
        $function = $($MyInvocation.MyCommand.Name)
        foreach($item in $PSBoundParameters.keys){
            $params = "$($params) -$($item) $($PSBoundParameters[$item])"
        }
        Write-MWALog -Status INFO -Message "Running $($function)$($params)" -Source $function
        $ret = $null
    }

    process{
        try{
            #region add your code here
            $ret = [PSCustomObject]@{
                Succeeded  = $true
                Function   = $function
                Name       = $Name
            }
            #endregion
        }
        catch{
            $ret = [PSCustomObject]@{
                Succeeded  = $false
                Function   = $function
                Scriptname = $($_.InvocationInfo.ScriptName)
                LineNumber = $($_.InvocationInfo.ScriptLineNumber)
                Activity   = $($_.CategoryInfo).Activity
                Message    = $($_.Exception.Message)
                Category   = $($_.CategoryInfo).Category
                Exception  = $($_.Exception.GetType().FullName)
                TargetName = $($_.CategoryInfo).TargetName
            }
            #don't forget to clear the error-object
            $error.Clear()
            Write-MWALog -Status ERROR -Message $ret -Source $function
        }
    }

    end{
        return $ret
    }
}

