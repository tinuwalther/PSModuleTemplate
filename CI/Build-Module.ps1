# Semantic Versioning: https://semver.org/

if((Get-Module -Name Pester).Version -match '^3\.\d{1}\.\d{1}'){
    Remove-Module -Name Pester
    Import-Module -Name Pester -MinimumVersion 5.2.2
}

Write-Host "[BUILD] [START] Launching Build Process" -ForegroundColor Green	

#region prepare folders
$Current          = (Split-Path -Path $MyInvocation.MyCommand.Path)
$Root             = ((Get-Item $Current).Parent).FullName
$BackupPath       = Join-Path -Path $Root -ChildPath "Backup"
$TestsPath        = Join-Path -Path $Root -ChildPath "Tests"
$CISourcePath     = Join-Path -Path $Root -ChildPath "CI"
$CodeSourcePath   = Join-Path -Path $Root -ChildPath "Code"
$TestsScript      = Join-Path -Path $TestsPath -ChildPath "Functions.Tests.ps1"
$TestsFailures    = Join-Path -Path $TestsPath -ChildPath "Failed.Tests.json"
$Settings         = Join-Path -Path $CISourcePath -ChildPath "Module-Settings.json"
#endregion

#region Module-Settings
if(Test-Path -Path $Settings){
    $ModuleSettings    = Get-content -Path $Settings | ConvertFrom-Json
    $ModuleName        = $ModuleSettings.ModuleName
    $ModuleDescription = $ModuleSettings.ModuleDescription
    $ModuleVersion     = $ModuleSettings.ModuleVersion
    $prompt            = Read-Host "Enter the Version number of this module in the Semantic Versioning notation [$( $ModuleVersion )]"
    if (!$prompt -eq "") {
        $ModuleVersion = $prompt
    }else{
        $ModuleVersion = [Version]$ModuleSettings.ModuleVersion
        $ModuleVersion = "{0}.{1}.{2}" -f $ModuleVersion.Major, $ModuleVersion.Minor, ($ModuleVersion.Build + 1)
    }
    $ModuleAuthor      = $ModuleSettings.ModuleAuthor
    $ModuleCompany     = $ModuleSettings.ModuleCompany
    $ModulePrefix      = $ModuleSettings.ModulePrefix
    $LastChange        = Read-Host 'Describe what did you change'
}
else{
    $ModuleName        = Read-Host 'Enter the name of the module without the extension'
    $ModuleVersion     = Read-Host 'Enter the Version number of this module in the Semantic Versioning notation [0.0.1]'
    if ([String]::IsNullOrEmpty($ModuleVersion)){$ModuleVersion = '0.0.1'}
    $ModuleDescription = Read-Host 'Enter the Description of the functionality provided by this module'
    $ModuleAuthor      = Read-Host 'Enter the Author of this module'
    $ModuleCompany     = Read-Host 'Enter the Company or vendor of this module'
    $ModulePrefix      = Read-Host 'Enter the Prefix for all functions of this module'
    $LastChange        = Read-Host 'Describe what did you change'
}
$ModuleName            =  $ModuleName.ToLower() -replace '\-', '.' # Lower-case is better for linux
[PSCustomObject] @{
    ModuleName        = $ModuleName
    ModuleVersion     = $ModuleVersion
    ModuleDescription = $ModuleDescription
    ModuleAuthor      = $ModuleAuthor
    ModuleCompany     = $ModuleCompany
    ModulePrefix      = $ModulePrefix
    LastChange        = $LastChange
} | ConvertTo-Json | Out-File -FilePath $Settings -Encoding utf8

Get-ChildItem -Path (Join-Path $CodeSourcePath -ChildPath 'Private') -Filter '*-*.ps1' | ForEach-Object {
    $newname   = $($_.Name -replace '-PRE',"-$($ModulePrefix)") 
    (Get-Content -Path $_.FullName) -replace '-PRE',"-$($ModulePrefix)" | Set-Content -Path $_.FullName
    Rename-Item -Path $_.FullName -NewName $newname #-PassThru
}
Get-ChildItem -Path (Join-Path $CodeSourcePath -ChildPath 'Public') -Filter '*-*.ps1' | ForEach-Object {
    $newname   = $($_.Name -replace '-PRE',"-$($ModulePrefix)") 
    (Get-Content -Path $_.FullName) -replace '-PRE',"-$($ModulePrefix)" | Set-Content -Path $_.FullName
    Rename-Item -Path $_.FullName -NewName $newname #-PassThru
}
#endregion

#region Pester Tests
if(Test-Path -Path $TestsFailures){
    $file      = Get-Item -Path $TestsFailures
    $timestamp = Get-Date ($file.LastWriteTime) -f 'yyyyMMdd_HHmmss'
    $newname   = $($file.Name -replace '.json',"-$($timestamp).json") 
    Rename-Item -Path $TestsFailures -NewName $newname
}

Write-Host "[BUILD] [TEST]  Running Function-Tests" -ForegroundColor Green
#$TestsResult = Invoke-Pester -Script $TestsScript -PassThru -Show None -> for Pester before 5.2.2
$TestsResult = Invoke-Pester -Script $TestsScript -Output Normal -PassThru
if($TestsResult.FailedCount -eq 0){    
    
    $ModuleFolderRootPath = Join-Path -Path $Root -ChildPath $ModuleName
    $ModuleFolderPath = Join-Path -Path $ModuleFolderRootPath -ChildPath $ModuleVersion
    #$ModuleFolderPath = $Root
    if(-not(Test-Path -Path $ModuleFolderPath)){
        $null = New-Item -Path $ModuleFolderPath -ItemType Directory -Force
    }
    #endregion

    #region Update the Module-File
    # Remove existent PSM1-File
    $ExportPath = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psm1"
    if(Test-Path $ExportPath){
        Write-Host "[BUILD] [PSM1 ] PSM1 file detected. Deleting..." -ForegroundColor Green
        #Remove-Item -Path $ExportPath -Force
        Move-Item -Path $ExportPath -Destination $BackupPath -Force -Confirm:$false
    }

    # Prepare new PSM1-File
    $Date = Get-Date
    "<#" | out-File -FilePath $ExportPath -Encoding utf8 -Append
    "    Generated at $($Date) by $($ModuleAuthor)" | out-File -FilePath $ExportPath -Encoding utf8 -Append
    "#>" | out-File -FilePath $ExportPath -Encoding utf8 -Append

    Write-Host "[BUILD] [Code ] Loading Class, public and private functions" -ForegroundColor Green
    $PrivateFunctions  = Get-ChildItem -Path (Join-Path $CodeSourcePath -ChildPath 'Private') -Filter '*-*.ps1' | sort-object Name
    $PublicFunctions   = Get-ChildItem -Path (Join-Path $CodeSourcePath -ChildPath 'Public') -Filter '*-*.ps1' | sort-object Name
    $MainPSM1Contents  = @()
    $MainPSM1Contents  += $PrivateFunctions
    $MainPSM1Contents  += $PublicFunctions

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
    if(Test-Path $FullModuleName){
        Move-Item -Path $FullModuleName -Destination $BackupPath -Force -Confirm:$false
    }

    $ModuleManifestSplat = @{
        Path              = $FullModuleName
        ModuleVersion     = $ModuleVersion
        Description       = $ModuleDescription
        Author            = $ModuleAuthor
        CompanyName       = $ModuleCompany
        RootModule        = "$($ModuleName).psm1"
        PowerShellVersion = '5.1'
    }
    New-ModuleManifest @ModuleManifestSplat

    Write-Host "[BUILD] [PSD1 ] Adding functions to export" -ForegroundColor Green
    $FunctionsToExport = $PublicFunctions.BaseName
    $Manifest = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psd1"
    Update-ModuleManifest -Path $Manifest -FunctionsToExport $FunctionsToExport -ModuleVersion $ModuleVersion

    Write-Host "[BUILD] [END  ] [PSD1] building Manifest" -ForegroundColor Green
    #endregion

    $ChangeLog = "$($ModuleVersion) | $($LastChange) | $(Get-Date -f 'yyyy-MM-dd') | $($ModuleAuthor)"
    Add-Content -Value $ChangeLog -Path (Join-Path $Root -ChildPath 'CHANGELOG.md')

    Write-Host "[BUILD] [END]   Launching Build Process" -ForegroundColor Green	
}
else{
    $FailedTests = $TestsResult.Failed | Select-Object -Property Name, Path, ExpandedName, ExpandedPath, Result, ErrorRecord, Duration, ItemType
    if($FailedTests){
        $FailedTests | ConvertTo-Json -Depth 1 -WarningAction Ignore | Out-File -FilePath $TestsFailures -Encoding utf8
        Write-Host "[BUILD] [END]   [TEST] Function-Tests, any Errors can be found in $($TestsFailures)" -ForegroundColor Red
    }else{
        Write-Warning "There is something wrong in paradise $($TestArray.Get()))"
    }
    Write-Host "[BUILD] [END]   Launching Build Process with $($TestsResult.FailedCount) Errors" -ForegroundColor Red	
}
#endregion

#region Module.Tests.ps1
Write-Host "`n"
Invoke-Pester -Script (Join-Path -Path $TestsPath -ChildPath "Module.Tests.ps1") -Output Detailed
#endregion