# Table of Contents

- [Table of Contents](#table-of-contents)
- [PowerShell Module Template](#powershell-module-template)
  - [README](#readme)
  - [CHANGELOG](#changelog)
  - [CI](#ci)
    - [Build-Module.ps1](#build-moduleps1)
      - [Usage](#usage)
    - [Module-Settings.json](#module-settingsjson)
  - [Code](#code)
    - [Get-PRETemplate.ps1](#get-pretemplateps1)
    - [Write-PRELog.ps1](#write-prelogps1)
  - [Module-Folder](#module-folder)
    - [Manifest-File](#manifest-file)
    - [Module-File](#module-file)
  - [Tests](#tests)
    - [Functions.Tests.ps1](#functionstestsps1)
    - [Failed.Tests.json](#failedtestsjson)
    - [Module.Tests.ps1](#moduletestsps1)

# PowerShell Module Template

How to create a new PowerShell-Module with PSModuleTemplate?

1. Create a new project in Git and clone it to your computer
2. git clone <https://github.com/tinuwalther/PSModuleTemplate.git>  
3. Copy the content from PSModuleTemplate into your new project
4. Update the README.md with your information
5. Save your function-files in the folder Code
6. Build your Module with Build-Module.ps1

## README

Information about your project.

## CHANGELOG

The Build-Module.ps1 update this file with your last change description.

## CI

This is the folder for all Continous Integration scripts like a script to automate the Module-File (Build-Module.ps1) and other scripts.

### Build-Module.ps1

This script builds your module automatically.  

Build-Module.ps1 running the Functions.Tests.ps1, if no errors occured it delete the existent Module-File (PSM1) and create a new Module-File (PSM1) with all of your functions.
The script also updates the Manifest-File (PSD1) with the functions to export. If the Manifest-File doesn't exists, it will be created.

Finally Build-Module.ps1 tests if your Module can be imported and removed without any errors. It tests also if the Module contains all of your exported functions.

#### Usage

Open the Terminal and navigate to the Git-Project. Start the Build-Module.ps1 and enter the answers:

````PowerShell
./CI/Build-Module.ps1
`````

`````text
[BUILD] [START] Launching Build Process
Enter the name of the module without the extension: Test-PSModuleTemplate
Enter the Version number of this module in the Semantic Versioning notation [1.0.0]: 0.0.1
Enter the Description of the functionality provided by this module: This is a PowerShell-Module to create simple PowerShell-Modules
Enter the Author of this module: Martin Walther  
Enter the Company or vendor of this module: Martin Walther Foto & IT
Enter the Prefix for all functions of this module: MWA
Describe what did you change: Initial upload
[BUILD] [TEST]  Running Function-Tests

Starting discovery in 1 files.
Discovery found 0 tests in 13ms.
Running tests.
Tests completed in 13ms
Tests Passed: 0, Failed: 0, Skipped: 0 NotRun: 0

[BUILD] [Code ] Loading Class, public and private functions
[BUILD] [START] [PSM1] Building Module PSM1
[BUILD] [END  ] [PSM1] building Module PSM1 
[BUILD] [START] [PSD1] Manifest PSD1
[BUILD] [PSD1 ] Adding functions to export
[BUILD] [END  ] [PSD1] building Manifest
[BUILD] [END]   Launching Build Process
`````

````PowerShell
Import-Module ./test.psmoduletemplate/                                                                
Get-Command -Module test.psmoduletemplate       
`````

`````text
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-PRETemplate                                    0.0.1      test.psmoduletemplate
`````

### Module-Settings.json

The settings-file will be created, if you build the module at the first time and contains the following properties:

    ModuleName
    ModuleVersion
    ModuleDescription
    ModuleAuthor
    ModuleCompany
    ModulePrefix
    LastChange

## Code

In this folder save all your functions as PS1-Files with the Name of the function you want to have in the Module. e.g. Get-PRETemplate.ps1.

### Get-PRETemplate.ps1

This is an example function-file, you can copy and rename this file for your own use. Before you build your module, please be sure that you renamed the function name within the file.

### Write-PRELog.ps1

This is an example Log-function to write information to the specified logfile. If no logfile is ommited, the default logfile will be used (<ModulePath\ModuleName.log>).

## Module-Folder

The Module-Folder will be created automatically with the Build-Module.script.

### Manifest-File

Automatically generated Manifest-file (PSD1), please update some settings by editing the file in vs-code.

### Module-File

PowerShell-Module-file (PSM1), contains all your functions from the Code-folder.

## Tests

This folder contains all the Pester-Test-scripts.  

### Functions.Tests.ps1

Functions.Tests.ps1 tests all of your scripts/functions in the folder Code.  

### Failed.Tests.json

This file will be created, if there were some errors in the Build-Module.

### Module.Tests.ps1

This is the file for your Function-Tests. Here you should write a test for each function to ensure, that your code is not damaged and is valid.
You can call this Tests in a GitHub-Action or CI/CD-Pipeline or simple manually.

````PowerShell
$TestsResult = Invoke-Pester -Script ./Tests/Module.Tests.ps1 -Output Detailed  -PassThru
`````

`````text
Describing Module Tests
 Context Import Module
   [+] Import test.psmoduletemplate should not throw 8ms (5ms|3ms)
   [+] Get-Command -Module test.psmoduletemplate should not throw 11ms (3ms|8ms)
   [+] Get-Command -Module test.psmoduletemplate should return commands 10ms (8ms|1ms)
 Context Functions
   [+] Get-PRETemplate should not throw 53ms (51ms|2ms)
 Context Remove Module
   [+] Removes test.psmoduletemplate should not throw 8ms (6ms|2ms)
   [+] Get-Module -Name test.psmoduletemplate should be NullOrEmpty 4ms (3ms|1ms)
Tests completed in 238ms
Tests Passed: 6, Failed: 0, Skipped: 0 NotRun: 0
`````
