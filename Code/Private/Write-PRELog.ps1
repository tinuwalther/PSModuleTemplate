function Write-PRELog{
    
    <#

        .SYNOPSIS
        Logging

        .DESCRIPTION
        Log in to file

        .PARAMETER LogFile
        Full path- and filname to log.

        .PARAMETER Status
        ERROR, WARNING, or INFO

        .PARAMETER Message
        A string message to log.

        .PARAMETER MaxLogFileSizeMB
        Max file-size of the logfile, if the file is greather than max-size it will be renamed.

        .EXAMPLE
        Write-Log -Status WARNING -Source "Module-Test" -Message "Test Write-Log"

        .NOTES
        2021-08-10, Martin Walther, 1.0.0, Initial version

    #>

    [CmdletBinding(SupportsShouldProcess=$True)]
    param(
        [Parameter(Mandatory=$false)]
        [string] $LogFile,

        [ValidateSet("ERROR","WARNING","INFO")]
        [Parameter(Mandatory=$true)]
        [string] $Status,

        [Parameter(Mandatory=$false)]
        [String] $Source='n/a',

        [Parameter(Mandatory=$false)]
        [String] $System,

        [Parameter(Mandatory=$true)]
        $Message,

        [Parameter(Mandatory=$false)]
        [int] $MaxLogFileSizeMB = 10
    )

    begin{
        #region Do not change this region
        $StartTime = Get-Date
        $function = $($MyInvocation.MyCommand.Name)
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Begin   ]', $function -Join ' ')
        #endregion
    }

    process{
        Write-Verbose $('[', (Get-Date -f 'yyyy-MM-dd HH:mm:ss.fff'), ']', '[ Process ]', $function -Join ' ')
        foreach($item in $PSBoundParameters.keys){ $params = "$($params) -$($item) $($PSBoundParameters[$item])" }
        if ($PSCmdlet.ShouldProcess($params.Trim())) {
            try{
                if([String]::IsNullOrEmpty($LogFile)){
                    $LogFile = $PSCommandPath -replace '.psm1', '.log'
                }
                Write-Verbose "Logfile: $LogFile"
        
                #region Test is logfile greater than MaxLogFileSizeMB
                if (Test-Path $LogFile){
                    $LogFileProperty = Get-Item $LogFile
                    $LogFileSizeMB   = $LogFileProperty.Length / 1mb
                    if($LogFileSizeMB -gt $MaxLogFileSizeMB){
                        Rename-Item -Path $LogFile -NewName "$($LogFileProperty.Name)_$(Get-Date -f 'yyyyMMddHHmmss').log"
                    }
                }  
                #endregion

                #region write loginformation
                if (-not(Test-Path $LogFile)){$null = New-Item $Logfile -type file}
                switch($Status){
                    'ERROR'   {$LogStatus = '[ERROR  ]'}
                    'WARNING' {$LogStatus = '[WARNING]'}
                    'INFO'    {$LogStatus = '[INFO   ]'}
                }
                $DateNow   = Get-Date -Format "dd.MM.yyyy HH:mm:ss.fff"
                #endregion

                #region Check User
                if($PSVersionTable.PSVersion.Major -lt 6){
                    $CurrentUser = $env:USERNAME
                }
                else{
                    if($IsMacOS)  {
                        $CurrentUser = id -un
                    }
                    if($IsLinux)  {
                        $CurrentUser = id -un
                    }
                    if($IsWindows){
                        $CurrentUser = $env:USERNAME
                    }
                }
                #endregion

                if (
                    ($Message -is [System.Object[]]) -or
                    ($Message -is [System.Management.Automation.PSCustomObject]) -or
                    ($Message -is [System.Collections.Specialized.OrderedDictionary])
                )
                {
                    for ($o = 0; $o -lt $Message.count; $o++){
                        Add-Content $LogFile -value "$($DateNow)`t$($LogStatus)`t[$($CurrentUser)]`t[$($Source)]`t$($Message[$o])"
                    }
                }else{
                    Add-Content $LogFile -value "$($DateNow)`t$($LogStatus)`t[$($CurrentUser)]`t[$($Source)]`t$($Message)"
                }
            }
            catch [Exception]{
                Write-Verbose "-> Catch block reached"
                $OutString = [PSCustomObject]@{
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
                $error.clear()
                $OutString | Format-List | Out-String | ForEach-Object { Write-Warning $_ }
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

