# Semantic Versioning: https://semver.org/

$ModuleName    = Read-Host 'Enter the name of the Module without the extension'
$ModuleVersion = Read-Host 'Enter the version of the Module in the Semantic Versioning notation'
$ModuleAuthor  = Read-Host 'Enter the fullname of the author of the Module'

Write-Host "[BUILD] [START] Launching Build Process" -ForegroundColor Yellow	

#region prepare folders
$Current          = (Split-Path -Path $MyInvocation.MyCommand.Path)
$Root             = ((Get-Item $Current).Parent).FullName
$ModuleFolderPath = Join-Path -Path $Root -ChildPath $ModuleName
#$ModuleFolderPath = $Root
$CodeSourcePath   = Join-Path -Path $Root -ChildPath "Code"
if(-not(Test-Path -Path $ModuleFolderPath)){New-Item -Path $ModuleFolderPath -ItemType Directory}
#endregion

#region Update the Module-File
# Remove existent PSM1-File
$ExportPath = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psm1"
if(Test-Path $ExportPath){
    Write-Host "[BUILD] [PSM1 ] PSM1 file detected. Deleting..." -ForegroundColor Yellow
    Remove-Item -Path $ExportPath -Force
}

# Prepare new PSM1-File
$Date = Get-Date
"<#" | out-File -FilePath $ExportPath -Encoding utf8 -Append
"    Generated at $($Date) by $($ModuleAuthor)" | out-File -FilePath $ExportPath -Encoding utf8 -Append
"#>" | out-File -FilePath $ExportPath -Encoding utf8 -Append

Write-Host "[BUILD] [Code ] Loading Class, public and private functions" -ForegroundColor Yellow
$PublicFunctions  = Get-ChildItem -Path $CodeSourcePath -Filter '*-*.ps1' | sort-object Name
$MainPSM1Contents = @()
$MainPSM1Contents += $PublicFunctions

#Creating PSM1
Write-Host "[BUILD] [START] [PSM1] Building Module PSM1" -ForegroundColor Yellow
"#region namespace $($ModuleName)" | out-File -FilePath $ExportPath -Encoding utf8 -Append
$MainPSM1Contents | ForEach-Object{
    Get-Content -Path $($_.FullName) | out-File -FilePath $ExportPath -Encoding utf8 -Append
}
"#endregion" | out-File -FilePath $ExportPath -Encoding utf8 -Append

Write-Host "[BUILD] [END  ] [PSM1] building Module PSM1 " -ForegroundColor Yellow
#endregion

#region Update the Manifest-File
Write-Host "[BUILD] [START] [PSD1] Manifest PSD1" -ForegroundColor Yellow
$FullModuleName = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psd1"
if(-not(Test-Path $FullModuleName)){
    New-ModuleManifest -Path $FullModuleName -ModuleVersion $ModuleVersion -Author $ModuleAuthor -RootModule "$($ModuleName).psm1" -PowerShellVersion 5.1
}

Write-Host "[BUILD] [PSD1 ] Adding functions to export" -ForegroundColor Yellow
$FunctionsToExport = $PublicFunctions.BaseName
$Manifest = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psd1"
Update-ModuleManifest -Path $Manifest -FunctionsToExport $FunctionsToExport

Write-Host "[BUILD] [END  ] [PSD1] building Manifest" -ForegroundColor Yellow
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
