# GitHub to WordPress Module Setup Script
# This script helps users set up the module for first-time use

param(
    [switch]$CreateConfig,
    [switch]$TestConfiguration,
    [switch]$InstallDependencies
)

Write-Host "GitHub to WordPress Module Setup" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check if running as script or interactively
if (-not $PSBoundParameters.Count) {
    Write-Host "`nThis setup script helps you configure the GitHub to WordPress module."
    Write-Host "Run with parameters for automated setup:" -ForegroundColor Gray
    Write-Host "  -CreateConfig       : Create a configuration file template" -ForegroundColor Gray
    Write-Host "  -TestConfiguration  : Test your current configuration" -ForegroundColor Gray
    Write-Host "  -InstallDependencies: Install recommended PowerShell modules" -ForegroundColor Gray
    Write-Host ""
    
    $action = Read-Host "What would you like to do? (1) Create config template, (2) Test config, (3) Install dependencies, (4) All"
    
    switch ($action) {
        "1" { $CreateConfig = $true }
        "2" { $TestConfiguration = $true }
        "3" { $InstallDependencies = $true }
        "4" { $CreateConfig = $true; $TestConfiguration = $true; $InstallDependencies = $true }
        default { Write-Host "Invalid selection. Exiting." -ForegroundColor Red; exit 1 }
    }
}

#region Install Dependencies

if ($InstallDependencies) {
    Write-Host "`n=== Installing Dependencies ===" -ForegroundColor Yellow
    
    # Check for PowerShellForGitHub module
    if (-not (Get-Module -ListAvailable -Name 'PowerShellForGitHub' -ErrorAction SilentlyContinue)) {
        Write-Host "Installing PowerShellForGitHub module..." -ForegroundColor Green
        try {
            Install-Module -Name PowerShellForGitHub -Scope CurrentUser -Force -AllowClobber
            Write-Host "✓ PowerShellForGitHub installed successfully" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to install PowerShellForGitHub: $_"
            Write-Host "You can install it manually with: Install-Module PowerShellForGitHub" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "✓ PowerShellForGitHub is already installed" -ForegroundColor Green
    }
}

#endregion

#region Create Configuration

if ($CreateConfig) {
    Write-Host "`n=== Creating Configuration Template ===" -ForegroundColor Yellow
    
    $configPath = "./config.json"
    
    if (Test-Path $configPath) {
        $overwrite = Read-Host "Configuration file already exists. Overwrite? (y/N)"
        if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
            Write-Host "Configuration creation skipped." -ForegroundColor Gray
        }
        else {
            Remove-Item $configPath -Force
        }
    }
    
    if (-not (Test-Path $configPath)) {
        Write-Host "`nPlease provide the following information:" -ForegroundColor White
        
        # GitHub Token
        Write-Host "`n1. GitHub Personal Access Token" -ForegroundColor Cyan
        Write-Host "   Create one at: https://github.com/settings/tokens" -ForegroundColor Gray
        Write-Host "   Required permissions: public_repo (or repo for private repos)" -ForegroundColor Gray
        $gitHubToken = Read-Host "   Enter your GitHub token"
        
        # WordPress Details
        Write-Host "`n2. WordPress Site Details" -ForegroundColor Cyan
        $wordPressUrl = Read-Host "   Enter your WordPress site URL (e.g., https://myblog.com)"
        $wordPressUsername = Read-Host "   Enter your WordPress username"
        
        Write-Host "`n3. WordPress Application Password" -ForegroundColor Cyan
        Write-Host "   Create one at: your-site/wp-admin/profile.php" -ForegroundColor Gray
        Write-Host "   Look for 'Application Passwords' section" -ForegroundColor Gray
        $wordPressPassword = Read-Host "   Enter your WordPress application password" -AsSecureString
        $wordPressPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($wordPressPassword))
        
        # Create configuration object
        $config = @{
            GitHubToken = $gitHubToken
            WordPressUrl = $wordPressUrl.TrimEnd('/')
            WordPressUsername = $wordPressUsername
            WordPressPassword = $wordPressPasswordPlain
        }
        
        # Save configuration
        try {
            $config | ConvertTo-Json -Depth 2 | Out-File -FilePath $configPath -Encoding UTF8
            Write-Host "✓ Configuration saved to $configPath" -ForegroundColor Green
            Write-Host "  Remember to keep this file secure and don't commit it to version control!" -ForegroundColor Yellow
        }
        catch {
            Write-Error "Failed to save configuration: $_"
        }
    }
}

#endregion

#region Test Configuration

if ($TestConfiguration) {
    Write-Host "`n=== Testing Configuration ===" -ForegroundColor Yellow
    
    try {
        # Import the module
        Import-Module ./GitHubToWordPress.psd1 -Force
        Write-Host "✓ Module imported successfully" -ForegroundColor Green
        
        # Load configuration
        if (Test-Path "./config.json") {
            Set-GitHubToWordPressConfig -ConfigFile "./config.json"
            Write-Host "✓ Configuration loaded from config.json" -ForegroundColor Green
        }
        else {
            Write-Warning "No config.json found. Please run setup with -CreateConfig first."
            return
        }
        
        # Test configuration
        $config = Get-GitHubToWordPressConfig
        Write-Host "Configuration Status:" -ForegroundColor White
        Write-Host "  GitHub Token: $(if ($config.GitHubTokenConfigured) { '✓ Configured' } else { '✗ Missing' })" -ForegroundColor $(if ($config.GitHubTokenConfigured) { 'Green' } else { 'Red' })
        Write-Host "  WordPress: $(if ($config.WordPressConfigured) { '✓ Configured' } else { '✗ Missing' })" -ForegroundColor $(if ($config.WordPressConfigured) { 'Green' } else { 'Red' })
        if ($config.WordPressConfigured) {
            Write-Host "  WordPress URL: $($config.WordPressUrl)" -ForegroundColor Gray
            Write-Host "  WordPress User: $($config.WordPressUsername)" -ForegroundColor Gray
        }
        
        # Test with a sample repository (dry run)
        if ($config.GitHubTokenConfigured) {
            Write-Host "`nTesting with sample repository (Microsoft PowerShell)..." -ForegroundColor White
            try {
                New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/microsoft/powershell" -DryRun
                Write-Host "✓ Dry run test successful!" -ForegroundColor Green
            }
            catch {
                Write-Warning "Dry run test failed: $_"
                Write-Host "This might be due to network restrictions or invalid credentials." -ForegroundColor Gray
            }
        }
        
    }
    catch {
        Write-Error "Configuration test failed: $_"
    }
}

#endregion

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan

if ($CreateConfig -or $TestConfiguration) {
    Write-Host "`nNext steps:" -ForegroundColor White
    Write-Host "1. Review the Examples.ps1 file for usage examples" -ForegroundColor Gray
    Write-Host "2. Try a dry run: New-GitHubToWordPressBlogPost -RepositoryUrl 'https://github.com/owner/repo' -DryRun" -ForegroundColor Gray
    Write-Host "3. Create your first blog post: New-GitHubToWordPressBlogPost -RepositoryUrl 'https://github.com/owner/repo'" -ForegroundColor Gray
}

Write-Host "`nFor help with any function, use Get-Help:" -ForegroundColor Gray
Write-Host "  Get-Help New-GitHubToWordPressBlogPost -Full" -ForegroundColor Gray