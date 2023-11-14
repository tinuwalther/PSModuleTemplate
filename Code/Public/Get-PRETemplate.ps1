
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

    [CmdletBinding(SupportsShouldProcess=$True)]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    begin{
        #region Do not change this region
        $StartTime = Get-Date
        $function = $($MyInvocation.MyCommand.Name)
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', $($function) -Join ' ')
        #endregion
    }

    process{
        foreach($item in $PSBoundParameters.keys){ $params = "$($params) -$($item) $($PSBoundParameters[$item])" }
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', "$($function)$($params)" -Join ' ')
        if ($PSCmdlet.ShouldProcess($params.Trim())) {
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
                    Function   = "$($function)$($params)"
                    Scriptname = $($_.InvocationInfo.ScriptName)
                    LineNumber = $($_.InvocationInfo.ScriptLineNumber)
                    Activity   = $($_.CategoryInfo).Activity
                    Message    = $($_.Exception.Message)
                    Category   = $($_.CategoryInfo).Category
                    Exception  = $($_.Exception.GetType().FullName)
                    TargetName = $($_.CategoryInfo).TargetName
                }
                $error.Clear()
                $OutString | Format-List | Out-String | ForEach-Object { Write-Warning $_ }
                Write-MWALog -Status ERROR -Message $ret -Source $function
            }
            finally {
                $ret
            }
        }
    }

    end{
        #region Do not change this region
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ End     ]', $function -Join ' ')
        $TimeSpan  = New-TimeSpan -Start $StartTime -End (Get-Date)
        $Formatted = $TimeSpan | ForEach-Object {
            '{1:0}h {2:0}m {3:0}s {4:000}ms' -f $_.Days, $_.Hours, $_.Minutes, $_.Seconds, $_.Milliseconds
        }
        Write-Verbose $('Finished in:', $Formatted -Join ' ')
        #endregion
    }
}

