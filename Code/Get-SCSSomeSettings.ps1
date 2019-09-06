
function Get-SCSSomeSettings{

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
        [Parameter(Mandatory = $false)]
        [String]$Param1
    )
    $function = $($MyInvocation.MyCommand.Name)
    Write-Verbose "Running $function"

    $ret = -404
    try{
        #your code here
        return $ret
    }
    catch{
        Write-Host "$($function): $($_.Exception.Message)" -ForegroundColor Yellow
        #don't forget to clear the error-object
        $error.Clear()
        $ret = -400
    }
    return $ret
}

<# 
=====================================================

                FUNCTION SPLITTER

=====================================================
#>
