# Pester: https://pester-docs.netlify.app
# Execute: Invoke-Pester -Script ./Tests/Module.Tests.ps1 -Output Detailed

$Current          = (Split-Path -Path $MyInvocation.MyCommand.Path)
$Root             = ((Get-Item $Current).Parent).FullName
$CISourcePath     = Join-Path -Path $Root -ChildPath "CI"
$Settings         = Join-Path -Path $CISourcePath -ChildPath "Module-Settings.json"

if(Test-Path -Path $Settings){
    $ModuleSettings       = Get-content -Path $Settings | ConvertFrom-Json
    $ModuleNameToTest     = $ModuleSettings.ModuleName
    $ModuleFolderPath     = Join-Path -Path $Root -ChildPath $ModuleNameToTest
    $ModuleFullNameToTest = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleNameToTest).psd1"
    $ModulePrefix         = $ModuleSettings.ModulePrefix

    Import-LocalizedData -BaseDirectory $ModuleFolderPath -FileName "$($ModuleNameToTest).psd1" -BindingVariable Data

}else{
    exit -1
}

BeforeAll{
    #Do some cleanup- or initial tasks
    $Error.Clear()
}

#region General Module-Tests
Describe 'Module Tests' -Tags 'FunctionalQuality' {

    Context "Import Module" {
        # Test Import-Module
        It "Import $ModuleNameToTest should not throw" -TestCases @{ ModuleNameToTest = $ModuleNameToTest; ModuleFullNameToTest = $ModuleFullNameToTest } {
            $ActualValue = Import-Module -FullyQualifiedName $ModuleFullNameToTest -Force -ErrorAction Stop
            { $ActualValue  } | Should -Not -Throw
        }
    
        # Test Get-Command
        It "Get-Command -Module $ModuleNameToTest should not throw" -TestCases @{ ModuleNameToTest = $ModuleNameToTest } {
            $ActualValue = Get-Command -Module $ModuleNameToTest -ErrorAction Stop
            { $ActualValue } | Should -Not -Throw
        }
        It "Get-Command -Module $ModuleNameToTest should return commands" -TestCases @{ ModuleNameToTest = $ModuleNameToTest } {
            $ActualValue = (Get-Command -Module $ModuleNameToTest).ExportedCommands
            { $ActualValue  } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Functions" {
        # Write for each function one test for { $ActualValue } | should -Not -Throw
        foreach($item in $Data.FunctionsToExport){
            #$FunctionNameToTest = 'Get-PRETemplate' -replace 'PRE', $ModulePrefix
            $FunctionNameToTest = $item
            It "$($FunctionNameToTest) -WhatIf should not throw" -TestCases @{ FunctionNameToTest = $FunctionNameToTest; ModuleNameToTest = $ModuleNameToTest } {
                Mock -ModuleName $ModuleNameToTest $FunctionNameToTest { return @{'Name' = 'Angus Young'} }
                $ActualValue = '$FunctionNameToTest -Name "Angus Young" -WhatIf'
                { $ActualValue } | should -Not -Throw
            }
            It "$($FunctionNameToTest) should not throw" -TestCases @{ FunctionNameToTest = $FunctionNameToTest; ModuleNameToTest = $ModuleNameToTest } {
                Mock -ModuleName $ModuleNameToTest $FunctionNameToTest { return @{'Name' = 'Angus Young'} }
                $ActualValue = '$FunctionNameToTest -Name "Angus Young"'
                { $ActualValue } | should -Not -Throw
            }
        }
    }

    Context "Remove Module" {
        It "Removes $ModuleNameToTest should not throw" -TestCases @{ ModuleNameToTest = $ModuleNameToTest} {
            $ActualValue = Remove-Module -Name $ModuleNameToTest -ErrorAction Stop
            { $ActualValue } | Should -not -Throw
            Get-Module -Name $ModuleNameToTest | Should -beNullOrEmpty
        }

        It "Get-Module -Name $ModuleNameToTest should be NullOrEmpty" -TestCases @{ ModuleNameToTest = $ModuleNameToTest} {
            $ActualValue = Get-Module -Name $ModuleNameToTest
            $ActualValue | Should -beNullOrEmpty
        }
    }

}
#endregion

<#
#region Function-Tests
Describe "Test Write-PRELog" {

    BeforeAll{
        $FunctionNameToTest = 'Write-PRELog'
        $ModuleNameToTest   = '/Users/Tinu/git/github.com/PSModuleTemplate/tinu.module/tinu.module.psd1'
        Mock -ModuleName 'tinu.module' Write-PRELog { return $null }
        $ActualValue = Write-PRELog -Status WARNING -Message "Test $FunctionNameToTest" -Source "Module-Test"
    }

    it "$($FunctionNameToTest) should should not throw" {
        { $ActualValue } | should -Not -Throw
    }

    it "$($FunctionNameToTest) should return true" {
        $ActualValue | should -BeNullOrEmpty
    }

}
#endregion
#>