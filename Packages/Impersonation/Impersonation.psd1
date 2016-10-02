#
# Module manifest for module 'Impersonation'
#
# Generated by: Guy Kv�rnberg
#

@{

# Script module or binary module file associated with this manifest
ModuleToProcess = 'Impersonation.psm1'

# Version number of this module.
ModuleVersion = '1.0'

# ID used to uniquely identify this module
GUID = 'dce3d9a4-f352-41b0-b8a9-acd3a3b03e8d'

# Author of this module
Author = 'Guy Kv�rnberg'

# Company or vendor of this module
CompanyName = 'Steria AS'

# Copyright statement for this module
Copyright = '(c) 2011 Guy Kv�rnberg. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This module provides a stack-like implementation of user impersonation.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = ''

# Processor architecture (None, X86, Amd64, IA64) required by this module
ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module
ScriptsToProcess = @(
	'InitTypes.ps1'
)

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()

# Modules to import as nested modules of the module specified in ModuleToProcess
NestedModules = @()

# Functions to export from this module
FunctionsToExport = @(
	'Push-ImpersonationContext'
	'Pop-ImpersonationContext'
)

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @()

# List of all modules packaged with this module
ModuleList = @()

# List of all files packaged with this module
FileList = @()

# Private data to pass to the module specified in ModuleToProcess
PrivateData = ''

}

