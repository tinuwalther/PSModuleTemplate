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
#endregion

#region Module-Settings
if(Test-Path -Path $Settings){
    $ModuleSettings    = Get-content -Path $Settings | ConvertFrom-Json
    $ModuleName        = $ModuleSettings.ModuleName
    $ModuleDescription = $ModuleSettings.ModuleDescription
    $ModuleVersion     = $ModuleSettings.ModuleVersion
    $prompt            = Read-Host "Enter the Version number of this module in the Semantic Versioning notation [$( $ModuleVersion )]"
    if (!$prompt -eq "") { $ModuleVersion = $prompt }
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
}
[PSCustomObject] @{
    ModuleName        = $ModuleName
    ModuleVersion     = $ModuleVersion
    ModuleDescription = $ModuleDescription
    ModuleAuthor      = $ModuleAuthor
    ModuleCompany     = $ModuleCompany
    ModulePrefix      = $ModulePrefix
} | ConvertTo-Json | Out-File -FilePath $Settings -Encoding utf8
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
    Update-ModuleManifest -Path $Manifest -FunctionsToExport $FunctionsToExport -ModuleVersion $ModuleVersion

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