# PowerShellModuleTemplate

How to create a PowerShell-Module with Git.

## README

Create a new Project in Git with a README.md and describe your project.

## CHANGELOG

Create a CHANGELOG.md in the root folder with the content in this CHANGELOG.md.  
Update this file if you change something on your module!

## CI

This is the folder for all Continous Integration scripts like a script to automate the Module-File (Build-Module.ps1) and other scripts.

### Build-Module.ps1

This script builds your module automatically. The script updates the Module-File (PSM1) with all of your functions and the Manifest-File (PSD1) with the functions to export. If the Manifest-File doesn't exists, it will be created.

## Code

In this folder create all your functions as PS1-Files with the Name of the function you want to have in the Module. e.g. Get-SomeSettings.ps1.

## Docs

This folder contains all the automatically generated Helpfiles from all of your function as Markdown-Files.

## Module-Folder

The Module-Folder will be created automatically with the Build-Module.script.

### Manifest-File

Manifest-file (PSD1)

### Module-File

PowerShell-Module-file (PSM1), contains all your functions from the Code-folder.

## Tests

This folder contains all the Pester-Test-scripts.
