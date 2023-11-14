#requires -modules platyPS

#region prepare folders
$Current           = (Split-Path -Path $MyInvocation.MyCommand.Path)
$Root              = ((Get-Item $Current).Parent).FullName
$CISourcePath      = Join-Path -Path $Root -ChildPath "CI"
$Settings          = Join-Path -Path $CISourcePath -ChildPath "Module-Settings.json"
$DocsSourcePath    = Join-Path -Path $Root -ChildPath "Docs"
#endregion

if(Test-Path -Path $Settings){
    $ModuleSettings    = Get-content -Path $Settings | ConvertFrom-Json
    $ModuleName        = $ModuleSettings.ModuleName
    $ModuleDescription = $ModuleSettings.ModuleDescription
    $ModuleVersion     = $ModuleSettings.ModuleVersion

    $ModuleFolderPath = Join-Path -Path $(Join-Path -Path $Root -ChildPath $ModuleName) -ChildPath $ModuleVersion
    $Manifest         = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psd1"
    $ModuleHelpFile   = "$($Root)\Module-help.md"
    
    Import-Module $Manifest

    $Functions = Get-Command -Module $ModuleName | Select-Object -ExpandProperty Name
    New-MarkdownHelp -Module $ModuleName -OutputFolder $DocsSourcePath

    $mdcontent = "# $($ModuleName)`n$($ModuleDescription).`n# Table of Contents`n"
    $mdcontent | Out-File -FilePath $ModuleHelpFile -Force
    
    $Functions | ForEach-Object {
        $mdcontent = "- [$($_)](#$($_.tolower())) "
        $mdcontent | Out-File -FilePath $ModuleHelpFile -Append
    }

    Get-ChildItem $DocsSourcePath | ForEach-Object {
        #"- [$($_.BaseName)](./Docs/$($_.Name))" | Out-File -FilePath "$($Root)\$($ModuleName).md" -Append
        Get-Content -Path $_.FullName -Filter '*.md' -Exclude 'README.md' | Out-File -FilePath $ModuleHelpFile -Append
    }
    
}else{
    throw "No settings found on $($Settings)"
}

