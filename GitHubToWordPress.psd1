@{
    # Module metadata
    RootModule = 'GitHubToWordPress.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'GitHub to WordPress Module'
    CompanyName = 'Unknown'
    Copyright = '(c) 2024. All rights reserved.'
    Description = 'A PowerShell module that updates a WordPress blog with posts highlighting changes to specified GitHub repositories.'
    
    # Minimum PowerShell version
    PowerShellVersion = '5.1'
    
    # Functions to export
    FunctionsToExport = @(
        'New-GitHubToWordPressBlogPost',
        'Get-GitHubRepositoryChanges',
        'Set-GitHubToWordPressConfig',
        'Get-GitHubToWordPressConfig'
    )
    
    # Cmdlets to export
    CmdletsToExport = @()
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('GitHub', 'WordPress', 'Blog', 'Automation', 'API')
            LicenseUri = ''
            ProjectUri = 'https://github.com/donnietaylor/github_to_wordpress'
            ReleaseNotes = 'Initial release of GitHub to WordPress module'
        }
    }
    
    # Required modules
    RequiredModules = @()
    
    # Assemblies to load
    RequiredAssemblies = @()
    
    # Script files to run before importing
    ScriptsToProcess = @()
    
    # Type files to load
    TypesToProcess = @()
    
    # Format files to load
    FormatsToProcess = @()
    
    # Nested modules to import
    NestedModules = @()
    
    # DSC resources to export
    DscResourcesToExport = @()
    
    # Compatibility
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # Help info URI
    HelpInfoURI = ''
    
    # Default prefix for commands
    DefaultCommandPrefix = ''
}