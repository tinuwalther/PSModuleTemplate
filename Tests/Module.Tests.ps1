# Pester: https://pester-docs.netlify.app
# Invoke-Pester -Script ./Tests/Module.Tests.ps1 -Output Detailed

BeforeAll{
    #Do some cleanup- or initial tasks
    $Error.Clear()
    Clear-Host
}

#region General Module-Tests
Describe 'Module Tests' -Tags 'FunctionalQuality' {

    $ModuleNameToTest   = 'tinu.module'

    Context "Import Module" {
        # Test Import-Module
        It "Import $ModuleNameToTest should not throw" {
            $ModuleFullNameToTest = '/Users/Tinu/git/github.com/PSModuleTemplate/tinu.module/tinu.module.psd1'
            $ActualValue = Import-Module $ModuleFullNameToTest -Force -ErrorAction Stop
            { $ActualValue  } | Should -Not -Throw
        }
    
        # Test Get-Command
        It "Get-Command -Module $ModuleNameToTest should not throw" {
            $ModuleNameToTest = 'tinu.module'
            $ActualValue = Get-Command -Module $ModuleNameToTest -ErrorAction Stop
            { $ActualValue } | Should -Not -Throw
        }
        It "Get-Command -Module $ModuleNameToTest should return commands" {
            $ModuleNameToTest = 'tinu.module'
            $ActualValue = (Get-Command -Module $ModuleNameToTest).ExportedCommands
            { $ActualValue  } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Functions" {
        # Write for each function one test for { $ActualValue } | should -Not -Throw
        $FunctionNameToTest = 'Write-PRELog'
        It "$($FunctionNameToTest) should not throw" {
            Mock -ModuleName 'tinu.module' Write-PRELog { return $null }
            $ActualValue = Write-PRELog -Status WARNING -Source "Module-Test" -Message "Test Write-PRELog"
            { $ActualValue } | should -Not -Throw
        }

        $FunctionNameToTest = 'Get-PRETemplate'
        It "$($FunctionNameToTest) should not throw" {
            Mock -ModuleName 'tinu.module' Get-PRETemplate { return @{'Name' = 'Angus Young'} }
            $ActualValue = Get-PRETemplate -Name "Angus Young"
            { $ActualValue } | should -Not -Throw
        }
    }

    Context "Remove Module" {
        It "Removes $ModuleNameToTest should not throw" {
            $ModuleNameToTest = 'tinu.module'
            $ActualValue = Remove-Module -Name $ModuleNameToTest -ErrorAction Stop
            { $ActualValue } | Should -not -Throw
            Get-Module -Name $ModuleNameToTest | Should -beNullOrEmpty
        }

        It "Get-Module -Name $ModuleNameToTest should be NullOrEmpty" {
            $ModuleNameToTest = 'tinu.module'
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