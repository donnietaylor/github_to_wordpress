# Basic tests for GitHub to WordPress module
# These tests verify that the module loads correctly and basic functionality works

Write-Host "Starting GitHub to WordPress Module Tests..." -ForegroundColor Cyan

#region Module Loading Tests

Write-Host "`n=== Module Loading Tests ===" -ForegroundColor Yellow

try {
    # Test 1: Module imports successfully
    Import-Module ./GitHubToWordPress.psd1 -Force
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Module import failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Check exported functions
$expectedFunctions = @(
    'New-GitHubToWordPressBlogPost',
    'Get-GitHubRepositoryChanges', 
    'Set-GitHubToWordPressConfig',
    'Get-GitHubToWordPressConfig'
)

$exportedFunctions = Get-Command -Module GitHubToWordPress | Select-Object -ExpandProperty Name
foreach ($func in $expectedFunctions) {
    if ($exportedFunctions -contains $func) {
        Write-Host "✓ Function $func is exported" -ForegroundColor Green
    } else {
        Write-Host "✗ Function $func is missing" -ForegroundColor Red
    }
}

#endregion

#region Configuration Tests

Write-Host "`n=== Configuration Tests ===" -ForegroundColor Yellow

# Test 3: Configuration functions work
try {
    $config = Get-GitHubToWordPressConfig
    Write-Host "✓ Get-GitHubToWordPressConfig works" -ForegroundColor Green
    Write-Host "  GitHub Token Configured: $($config.GitHubTokenConfigured)" -ForegroundColor Gray
    Write-Host "  WordPress Configured: $($config.WordPressConfigured)" -ForegroundColor Gray
}
catch {
    Write-Host "✗ Get-GitHubToWordPressConfig failed: $_" -ForegroundColor Red
}

# Test 4: Set configuration (with dummy values)
try {
    Set-GitHubToWordPressConfig -GitHubToken "test_token" -WordPressUrl "https://test.com" -WordPressUsername "test" -WordPressPassword "test"
    $config = Get-GitHubToWordPressConfig
    if ($config.GitHubTokenConfigured -and $config.WordPressConfigured) {
        Write-Host "✓ Set-GitHubToWordPressConfig works" -ForegroundColor Green
    } else {
        Write-Host "✗ Configuration not properly set" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Set-GitHubToWordPressConfig failed: $_" -ForegroundColor Red
}

#endregion

#region Parameter Validation Tests

Write-Host "`n=== Parameter Validation Tests ===" -ForegroundColor Yellow

# Test 5: Repository URL parsing
try {
    # This should fail gracefully without a valid GitHub token
    $result = Get-GitHubRepositoryChanges -RepositoryUrl "https://github.com/microsoft/powershell" -ErrorAction SilentlyContinue
    if ($Error.Count -gt 0) {
        # Expected to fail due to invalid token, but should parse URL correctly
        if ($Error[0].Exception.Message -like "*GitHub*" -or $Error[0].Exception.Message -like "*token*" -or $Error[0].Exception.Message -like "*401*" -or $Error[0].Exception.Message -like "*authentication*") {
            Write-Host "✓ Repository URL parsing works (fails correctly on auth)" -ForegroundColor Green
        } else {
            Write-Host "✗ Unexpected error: $($Error[0].Exception.Message)" -ForegroundColor Red
        }
        $Error.Clear()
    }
}
catch {
    if ($_.Exception.Message -like "*GitHub*" -or $_.Exception.Message -like "*token*" -or $_.Exception.Message -like "*401*" -or $_.Exception.Message -like "*authentication*") {
        Write-Host "✓ Repository URL parsing works (fails correctly on auth)" -ForegroundColor Green
    } else {
        Write-Host "✗ Repository URL parsing failed unexpectedly: $_" -ForegroundColor Red
    }
}

# Test 6: Invalid repository URL
try {
    Get-GitHubRepositoryChanges -RepositoryUrl "invalid-url" -ErrorAction Stop
    Write-Host "✗ Should have failed with invalid URL" -ForegroundColor Red
}
catch {
    if ($_.Exception.Message -like "*Invalid GitHub repository URL*") {
        Write-Host "✓ Invalid URL properly rejected" -ForegroundColor Green
    } else {
        Write-Host "✗ Wrong error for invalid URL: $_" -ForegroundColor Red
    }
}

#endregion

#region Help and Documentation Tests

Write-Host "`n=== Help and Documentation Tests ===" -ForegroundColor Yellow

# Test 7: Check that help is available for main functions
$functionsToCheck = @('New-GitHubToWordPressBlogPost', 'Get-GitHubRepositoryChanges', 'Set-GitHubToWordPressConfig')

foreach ($func in $functionsToCheck) {
    try {
        $help = Get-Help $func -ErrorAction Stop
        if ($help.Synopsis -and $help.Description) {
            Write-Host "✓ Help available for $func" -ForegroundColor Green
        } else {
            Write-Host "✗ Incomplete help for $func" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ No help available for $func" -ForegroundColor Red
    }
}

#endregion

#region Dry Run Tests

Write-Host "`n=== Dry Run Tests ===" -ForegroundColor Yellow

# Test 8: Dry run should work without WordPress configuration
try {
    # Clear WordPress config for this test
    Set-GitHubToWordPressConfig -GitHubToken "test_token"
    
    # This should work in dry run mode even without WordPress config
    New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/microsoft/powershell" -DryRun -ErrorAction Stop
    Write-Host "✗ Dry run should have failed without WordPress config" -ForegroundColor Red
}
catch {
    if ($_.Exception.Message -like "*GitHub token*" -or $_.Exception.Message -like "*authentication*") {
        Write-Host "✓ Dry run correctly requires GitHub token" -ForegroundColor Green
    } else {
        Write-Host "✗ Unexpected dry run error: $_" -ForegroundColor Red
    }
}

#endregion

#region Module Information Tests

Write-Host "`n=== Module Information Tests ===" -ForegroundColor Yellow

# Test 9: Module manifest information
try {
    $moduleInfo = Get-Module GitHubToWordPress
    Write-Host "✓ Module Version: $($moduleInfo.Version)" -ForegroundColor Green
    Write-Host "✓ Module Author: $($moduleInfo.Author)" -ForegroundColor Green
    Write-Host "✓ Module Description: $($moduleInfo.Description)" -ForegroundColor Green
    
    if ($moduleInfo.ExportedFunctions.Count -eq 4) {
        Write-Host "✓ Correct number of exported functions: $($moduleInfo.ExportedFunctions.Count)" -ForegroundColor Green
    } else {
        Write-Host "✗ Wrong number of exported functions: $($moduleInfo.ExportedFunctions.Count)" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Failed to get module information: $_" -ForegroundColor Red
}

#endregion

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Tests completed. Review the results above." -ForegroundColor White
Write-Host "For full functionality testing, configure real GitHub and WordPress credentials and run Examples.ps1" -ForegroundColor Gray