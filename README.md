# Table of Contents

- [Table of Contents](#table-of-contents)
- [PowerShell Module Template](#powershell-module-template)
  - [README](#readme)
  - [CHANGELOG](#changelog)
  - [CI](#ci)
    - [Build-Module.ps1](#build-moduleps1)
    - [Module-Settings.json](#module-settingsjson)
  - [Code](#code)
    - [Get-SCSSomeSettings.ps1](#get-scssomesettingsps1)
  - [Module-Folder](#module-folder)
    - [Manifest-File](#manifest-file)
    - [Module-File](#module-file)
  - [Tests](#tests)
    - [Functions.Tests.ps1](#functionstestsps1)
    - [Functions.Tests.json](#functionstestsjson)

# PowerShell Module Template

How to create a new PowerShell-Module with PSModuleTemplate?

1. Create a new project in Git and clone it to your computer
2. git clone <https://github.com/tinuwalther/PSModuleTemplate.git>  
3. Copy the content from PSModuleTemplate into your new project
4. Update the README.md and CHANGELOG.md with your information
5. Save your function-files in the folder Code
6. Build your Module with Build-Module.ps1

## README

Information about your project.

## CHANGELOG

Update this file whenever you make changes on your module!

## CI

This is the folder for all Continous Integration scripts like a script to automate the Module-File (Build-Module.ps1) and other scripts.

### Build-Module.ps1

This script builds your module automatically.  

Build-Module.ps1 running the Functions.Tests.ps1, if no errors occured it delete the existent Module-File (PSM1) and create a new Module-File (PSM1) with all of your functions.
The script also updates the Manifest-File (PSD1) with the functions to export. If the Manifest-File doesn't exists, it will be created.

Finally Build-Module.ps1 tests if your Module can be imported and removed without any errors. It tests also if the Module contains all of your exported functions.

### Module-Settings.json

The settings-file will be created, if you build the module at the first time and contains the following properties:

    ModuleName
    ModuleVersion
    ModuleDescription
    ModuleAuthor
    ModuleCompany

## Code

In this folder save all your functions as PS1-Files with the Name of the function you want to have in the Module. e.g. Get-SCSSomeSettings.ps1.

### Get-SCSSomeSettings.ps1

This is an example function-file, you can copy and rename this file for your own use. Before you build your module, please delete the Get-SCSSomeSettings.ps1.

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

### Functions.Tests.json

This file will be created, if there were some errors in the Build-Module.
