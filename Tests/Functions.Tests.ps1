# Some examples are from Josh Burkard, thanks!
# https://www.burkard.it/2019/08/pester-tests-for-powershell-functions/

#region declarations
$Current          = (Split-Path -Path $MyInvocation.MyCommand.Path)
$Root             = ((Get-Item $Current).Parent).FullName
$CodeSourcePath   = Join-Path -Path $Root -ChildPath "Code"
$CommonPrefix     = 'SCS'

 Get-ChildItem -Path $CodeSourcePath -Filter "*.ps1" | ForEach-Object {

    Describe "Testing Code-file $($_.Name)" {

        $ScriptName = $_.BaseName
        $Verb = @( $($_.Name) -split '-' )[0]

        Context "Naming" {
            It "$ScriptName should have an approved verb" {
                ( $Verb -in @( Get-Verb ).Verb ) | Should -Be $true
            }
    
            try {
                $FunctionPrefix = @( $ScriptName -split '-' )[1].Substring( 0, $CommonPrefix.Length )
            }
            catch {
                $FunctionPrefix = @( $ScriptName -split '-' )[1]
            }
            It "$ScriptName Noun should have the Prefix '$($CommonPrefix)'" {
                $FunctionPrefix | Should -match $CommonPrefix
            }
        }

        . $_.FullName
        $DetailedHelp  = Get-Help $ScriptName -Detailed
        $ScriptCommand = Get-Command -Name $ScriptName -All
        $Ast           = $ScriptCommand.ScriptBlock.Ast
        
        Context "Synopsis" {
            It "$ScriptName should have a SYNOPSIS" {
                ( $DetailedHelp -match 'SYNOPSIS' ) | Should -Be $true
            }
    
            It "$ScriptName should have a DESCRIPTION" {
                ( $DetailedHelp -match 'DESCRIPTION' ) | Should -Be $true
            }
    
            It "$ScriptName should have a EXAMPLE" {
                ( $DetailedHelp -match 'EXAMPLE' ) | Should -Be $true
            }

        }

        Context "Parameters" {

            It "$ScriptName $($_.Name) should have a function $ScriptName" {
                ($Ast -match $ScriptName) | Should -be $true
            }

            It "$ScriptName should have a CmdletBinding" {
                [boolean]( @( $Ast.FindAll( { $true } , $true ) ) | Where-Object { $_.TypeName.Name -eq 'cmdletbinding' } ) | Should -Be $true
            }

            $DefaultParams = @( 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable')
            foreach ( $p in @( $ScriptCommand.Parameters.Keys | Where-Object { $_ -notin $DefaultParams } | Sort-Object ) ) {
                It "$ScriptName the Help-text for paramater '$( $p )' should exist" {
                    ( $p -in $DetailedHelp.parameters.parameter.name ) | Should -Be $true
                }
    
                $Declaration = ( ( @( $Ast.FindAll( { $true } , $true ) ) | Where-Object { $_.Name.Extent.Text -eq "$('$')$p" } ).Extent.Text -replace 'INT32', 'INT' )
                $VariableType = ( "\[$( $ScriptCommand.Parameters."$p".ParameterType.Name )\]" -replace 'INT32', 'INT' )
                $VariableTypeFull = "\[$( $ScriptCommand.Parameters."$p".ParameterType.FullName )\]"
                $VariableType = $ScriptCommand.Parameters."$p".ParameterType.Name -replace 'INT32', 'INT'
                It "$ScriptName type '[$( $ScriptCommand.Parameters."$p".ParameterType.Name )]' should be declared for parameter '$( $p )'" {
                    ( ( $Declaration -match $VariableType ) -or ( $Declaration -match $VariableTypeFull ) ) | Should -Be $true
                }
            }
    
        }

        Context "Variables" {
            It "$ScriptName should have a function-variable" {
                ($Ast -match '\$function\s=\s\$\(\$MyInvocation.MyCommand.Name\)') | Should -be $true
            }

            $code = $ScriptCommand.ScriptBlock
            $ScriptVariables = $code.Ast.FindAll( { $true } , $true ) |
                Where-Object { $_.GetType().Name -eq 'VariableExpressionAst' } |
                Select-Object -Property VariablePath -ExpandProperty Extent
    
            foreach ( $sv in @( $ScriptVariables | Select-Object -ExpandProperty Text -Unique | Sort-Object ) ) {
                It "$ScriptName variable '$( $sv )' should be in same (upper/lower) case everywhere" {
                    [boolean]( $ScriptVariables | Where-Object { ( ( $_.Text -eq $sv ) -and ( $_.Text -cne $sv ) ) } ) | Should -Be $false
                }
            }
        }
        
        Context "Error-Handling" {
            It "$ScriptName should have a try-catch-block" {
                (($Ast -match 'try') -and ($Ast -match 'catch') -and ($Ast -match '\$error.Clear()')) | Should -be $true
            }
        }
    }
}

