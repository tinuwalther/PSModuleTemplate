
- [PowerShell Module Template](#powershell-module-template)
  - [README](#readme)
  - [CHANGELOG](#changelog)
  - [CI](#ci)
    - [Build-Module.ps1](#build-moduleps1)
  - [Code](#code)
  - [Module-Folder](#module-folder)
    - [Manifest-File](#manifest-file)
    - [Module-File](#module-file)
  - [Tests](#tests)

# PowerShell Module Template

How to create a PowerShell-Module with Git?

git clone <https://github.com/tinuwalther/PSModuleTemplate.git>

## README

Create a new project in Git, clone it to your computer and copy the content from this project into your new project. Update the README.md and CHANGELOG.md with your information.

## CHANGELOG

Update this file whenever you make changes on your module!

## CI

This is the folder for all Continous Integration scripts like a script to automate the Module-File (Build-Module.ps1) and other scripts.

### Build-Module.ps1

Before you run Build-Module.ps1, please make sure that Tests\Functions.Tests.ps1 was executed without any errors.

This script builds your module automatically. The script updates the Module-File (PSM1) with all of your functions and the Manifest-File (PSD1) with the functions to export. If the Manifest-File doesn't exists, it will be created.

## Code

In this folder save all your functions as PS1-Files with the Name of the function you want to have in the Module. e.g. Get-SomeSettings.ps1.

## Module-Folder

The Module-Folder will be created automatically with the Build-Module.script.

### Manifest-File

Automatically generated Manifest-file (PSD1), please update some settings by editing the file in vs-code.

### Module-File

PowerShell-Module-file (PSM1), contains all your functions from the Code-folder.

## Tests

This folder contains all the Pester-Test-scripts.
Functions.Tests.ps1 tests all of your scripts/functions in the folder Code.
