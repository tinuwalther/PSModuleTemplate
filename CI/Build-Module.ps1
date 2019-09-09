# Semantic Versioning: https://semver.org/

Write-Host "[BUILD] [START] Launching Build Process" -ForegroundColor Green	

#region prepare folders
$Current          = (Split-Path -Path $MyInvocation.MyCommand.Path)
$Root             = ((Get-Item $Current).Parent).FullName
$TestsPath        = Join-Path -Path $Root -ChildPath "Tests"
$CISourcePath     = Join-Path -Path $Root -ChildPath "CI"
$TestsScript      = Join-Path -Path $TestsPath -ChildPath "Functions.Tests.ps1"
$TestsFailures    = Join-Path -Path $TestsPath -ChildPath "Functions.Tests.json"
$Settings         = Join-Path -Path $CISourcePath -ChildPath "Module-Settings.json"
$HelpPath         = Join-Path -Path $Root -ChildPath "Help"
#endregion

#region Module-Settings
if(Test-Path -Path $Settings){
    $ModuleSettings    = Get-content -Path $Settings | ConvertFrom-Json
    $ModuleName        = $ModuleSettings.ModuleName
    $ModuleDescription = $ModuleSettings.ModuleDescription
    $ModuleVersion     = $ModuleSettings.ModuleVersion
    $ModuleAuthor      = $ModuleSettings.ModuleAuthor
    $ModuleCompany     = $ModuleSettings.ModuleCompany
    $ModulePrefix      = $ModuleSettings.ModulePrefix
}
else{
    $ModuleName        = Read-Host 'Enter the name of the module without the extension'
    $ModuleVersion     = Read-Host 'Enter the Version number of this module in the Semantic Versioning notation'
    $ModuleDescription = Read-Host 'Enter the Description of the functionality provided by this module'
    $ModuleAuthor      = Read-Host 'Enter the Author of this module'
    $ModuleCompany     = Read-Host 'Enter the Company or vendor of this module'
    $ModulePrefix      = Read-Host 'Enter the Prefix for all functions of this module'
    [PSCustomObject] @{
        ModuleName        = $ModuleName
        ModuleVersion     = $ModuleVersion
        ModuleDescription = $ModuleDescription
        ModuleAuthor      = $ModuleAuthor
        ModuleCompany     = $ModuleCompany
        ModulePrefix      = $ModulePrefix
    } | ConvertTo-Json | Out-File -FilePath $Settings -Encoding utf8
}
#endregion

#Running Pester Tests
if(Test-Path -Path $TestsFailures){
    $file      = Get-Item -Path $TestsFailures
    $timestamp = Get-Date ($file.LastWriteTime) -f 'yyyyMMdd_HHmmss'
    $newname   = $($file.Name -replace '.json',"-$($timestamp).json") 
    Rename-Item -Path $TestsFailures -NewName $newname
}
Write-Host "[BUILD] [TEST]  Running Function-Tests" -ForegroundColor Green
$TestsResult      = Invoke-Pester -Script $TestsScript -PassThru -Show None
if($TestsResult.FailedCount -eq 0){    
    $ModuleFolderPath = Join-Path -Path $Root -ChildPath $ModuleName
    #$ModuleFolderPath = $Root
    $CodeSourcePath   = Join-Path -Path $Root -ChildPath "Code"
    if(-not(Test-Path -Path $ModuleFolderPath)){
        $null = New-Item -Path $ModuleFolderPath -ItemType Directory
    }
    #endregion

    #region Update the Module-File
    # Remove existent PSM1-File
    $ExportPath = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psm1"
    if(Test-Path $ExportPath){
        Write-Host "[BUILD] [PSM1 ] PSM1 file detected. Deleting..." -ForegroundColor Green
        Remove-Item -Path $ExportPath -Force
    }

    # Prepare new PSM1-File
    $Date = Get-Date
    "<#" | out-File -FilePath $ExportPath -Encoding utf8 -Append
    "    Generated at $($Date) by $($ModuleAuthor)" | out-File -FilePath $ExportPath -Encoding utf8 -Append
    "#>" | out-File -FilePath $ExportPath -Encoding utf8 -Append

    Write-Host "[BUILD] [Code ] Loading Class, public and private functions" -ForegroundColor Green
    $PublicFunctions  = Get-ChildItem -Path $CodeSourcePath -Filter '*-*.ps1' | sort-object Name
    $MainPSM1Contents = @()
    $MainPSM1Contents += $PublicFunctions

    #Creating PSM1
    Write-Host "[BUILD] [START] [PSM1] Building Module PSM1" -ForegroundColor Green
    "#region namespace $($ModuleName)" | out-File -FilePath $ExportPath -Encoding utf8 -Append
    $MainPSM1Contents | ForEach-Object{
        Get-Content -Path $($_.FullName) | out-File -FilePath $ExportPath -Encoding utf8 -Append
    }
    "#endregion" | out-File -FilePath $ExportPath -Encoding utf8 -Append

    Write-Host "[BUILD] [END  ] [PSM1] building Module PSM1 " -ForegroundColor Green
    #endregion

    #region Update the Manifest-File
    Write-Host "[BUILD] [START] [PSD1] Manifest PSD1" -ForegroundColor Green
    $FullModuleName = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psd1"
    if(-not(Test-Path $FullModuleName)){
        New-ModuleManifest -Path $FullModuleName -ModuleVersion $ModuleVersion -Description $ModuleDescription -Author $ModuleAuthor -CompanyName $ModuleCompany -RootModule "$($ModuleName).psm1" -PowerShellVersion 5.1
    }

    Write-Host "[BUILD] [PSD1 ] Adding functions to export" -ForegroundColor Green
    $FunctionsToExport = $PublicFunctions.BaseName
    $Manifest = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psd1"
    Update-ModuleManifest -Path $Manifest -FunctionsToExport $FunctionsToExport

    Write-Host "[BUILD] [END  ] [PSD1] building Manifest" -ForegroundColor Green
    #endregion

    #region General Module-Tests
    if((Get-Module -Name Pester).Version -match '^3\.\d{1}\.\d{1}'){
        Remove-Module -Name Pester
        Import-Module -Name Pester -MinimumVersion 4.4.1
    }

    Describe 'General module control' -Tags 'FunctionalQuality'   {

        It "Import $ModuleName without errors" {
            { Import-Module -Name $Manifest -Force -ErrorAction Stop } | Should Not Throw
            Get-Module $ModuleName | Should Not BeNullOrEmpty
        }

        It "Get-Command $ModuleName without errors" {
            { Get-Command -Module $ModuleName -ErrorAction Stop } | Should Not Throw
            Get-Command -Module $ModuleName | Should Not BeNullOrEmpty
        }

        $FunctionsToExport | ForEach-Object {
            $functionname = $_
            It "Get-Command -Module $ModuleName should include Function $($functionname)" {
                Get-Command -Module $ModuleName | ForEach-Object { 
                    {if($functionname -match $_.Name){$true}} | should -betrue   
                }
            }
        }

        It "Removes $ModuleName without error" {
            { Remove-Module -Name $ModuleName -ErrorAction Stop} | Should not Throw
            Get-Module $ModuleName | Should beNullOrEmpty
        }

    }
    #endregion
    Write-Host "[BUILD] [END]   Launching Build Process" -ForegroundColor Green	

    #region build Help files
    Write-Host "[BUILD] [START] Launching build Help files" -ForegroundColor Green	

    Import-Module -Name $Manifest
    $Functions = Get-Command -Module $ModuleName -CommandType Function

    if ( -not ( Test-Path -Path $HelpPath ) ) {
        New-Item -Path $HelpPath -ItemType Directory | Out-Null
    }

    $FunctionName = @( $Functions )[0].Name
    foreach ( $FunctionName in @( $Functions | Sort-Object Name | Select-Object -ExpandProperty Name ) ) {
        # $Help = Get-Help $FunctionName -Full -Path $FunctionName
        $Help = Get-Help  $FunctionName 
        $Function = Get-Command $FunctionName
        
        $Ast = $Function.ScriptBlock.Ast
        $Examples = @( $Ast.GetHelpContent().EXAMPLES )
    
        #region create file content
            #region function name, SYNOPSIS
                $FileContent = @"
# $( $Help.Name )

## SYNOPSIS

$( $Help.Synopsis )


"@
            #endregion function name, SYNOPSIS
    
            #region SYNTAX
                $FileContent += @"
## SYNTAX

``````powershell
$( ( ( $Help.syntax | Out-String ) -replace "`r`n", "`r`n`r`n" ).Trim() )
``````


"@
            #endregion SYNTAX
    
            #region DESCRIPTION
                $FileContent += @"
## DESCRIPTION

$( ( $Help.description | Out-String ).Trim() )


"@
            #endregion DESCRIPTION
    
            #region PARAMETERS
                $FileContent += @"
## PARAMETERS


"@
                foreach ($parameter in $Help.parameters.parameter) {
                    $FileContent += @"
### -$($parameter.name) &lt;$($parameter.type.name)&gt;

$( ( $parameter.description | Out-String ).Trim() )

``````
$( ( ( ( $parameter | Out-String ).Trim() -split "`r`n")[-5..-1] | % { $_.Trim() } ) -join "`r`n" )

"@
                    if ( $Function.Parameters."$( $parameter.name )".Attributes[1].ValidValues ) {
                        $FileContent += @"

Valid Values:

"@
                        ( $Function.Parameters."$( $parameter.name )".Attributes[1].ValidValues ) | foreach {
                            $FileContent += @"
- $( $_ )
    
"@
                        }
                    }
                    $FileContent += @"
``````


"@
                }
            #endregion PARAMETERS
    
            #region INPUTS
                if ( $Help.inputTypes.inputType.type.name ) {
                    $FileContent += @"
## INPUTS

$( $Help.inputTypes.inputType.type.name )


"@
                }
            #endregion INPUTS
    
            #region OUTPUTS
                $FileContent += @"
## OUTPUTS

$( @( $Help.returnValues.returnValue )[0].type.name)


"@
            #endregion OUTPUTS
    
            #region NOTES
                if ( ( $Help.alertSet.alert | Out-String ).Trim() ) {
                    $FileContent += @"
## NOTES

``````
$( ( $Help.alertSet.alert | Out-String ).Trim() )
``````


"@
                }
            #endregion NOTES
    
            #region EXAMPLES
                $FileContent += @"
## EXAMPLES


"@
                for ($i = 0; $i -lt $Examples.Count; $i++) {
                    $FileContent += @"
### EXAMPLE $( $i + 1 )

``````powershell
$( ( @( $examples )[ $i ] ).ToString().Trim() )
``````


"@
                }
                <#
                foreach ($example in $Help.examples.example) {
                    $FileContent += @"
    ### $(($example.title -replace '-*', '').Trim())
    
``````powershell
$( @( $example.code ) -join "`r`n" )
``````

"@
                }
                #>
            #endregion EXAMPLES

            $FileContent = $FileContent -replace "$( [System.Environment]::NewLine )$( [System.Environment]::NewLine )$( [System.Environment]::NewLine )", "$( [System.Environment]::NewLine )$( [System.Environment]::NewLine )"

            
        #endregion create file content
    
        #region save file
            $FileName = Join-Path -Path $HelpPath -ChildPath "$( $FunctionName ).md"
            if ( Test-Path -Path $FileName ) {
                Remove-Item -Path $FileName -Force -Confirm:$false | Out-Null
            }
            $FileContent | Out-File -FilePath $FileName -Force
        #endregion save file
    }
    Write-Host "[BUILD] [END]   Launching build Help files" -ForegroundColor Green	

#endregion build Help files

}
else{
    $TestsArray = $TestsResult.TestResult | ForEach-Object {
        if($_.Passed -eq $false){
            [PSCustomObject] @{
                Describe = $_.Describe
                Context  = $_.Context
                Test     = $_.Name
                Result   = $_.Result
                Message  = $_.FailureMessage
            }
        }
    }
    $TestsArray | ConvertTo-Json | Out-File -FilePath $TestsFailures -Encoding utf8
    Write-Host "[BUILD] [END]   [TEST] Function-Tests, any Errors can be found in $($TestsFailures)" -ForegroundColor Red
    Write-Host "[BUILD] [END]   Launching Build Process with $($TestsResult.FailedCount) Errors" -ForegroundColor Red	
}