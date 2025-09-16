# GitHub to WordPress Module - Usage Examples
# These examples demonstrate how to use the module in various scenarios

# Import the module
Import-Module ./GitHubToWordPress.psd1

#region Basic Configuration Examples

# Example 1: Configure with direct parameters
Set-GitHubToWordPressConfig -GitHubToken "ghp_your_token_here" `
                           -WordPressUrl "https://myblog.com" `
                           -WordPressUsername "admin" `
                           -WordPressPassword "xxxx xxxx xxxx xxxx"

# Example 2: Configure using a JSON file
# First create config.json with your credentials, then:
# Set-GitHubToWordPressConfig -ConfigFile "./config.json"

# Example 3: Check current configuration
Get-GitHubToWordPressConfig

#endregion

#region Basic Usage Examples

# Example 4: Create a blog post from a popular repository
New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/microsoft/powershell"

# Example 5: Use owner/repository format instead of URL
New-GitHubToWordPressBlogPost -Owner "microsoft" -Repository "vscode"

# Example 6: Preview what the blog post would look like (dry run)
New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/microsoft/powershell" -DryRun

#endregion

#region Advanced Usage Examples

# Example 7: Create a blog post with custom date range
$twoWeeksAgo = (Get-Date).AddDays(-14)
New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/microsoft/powershell" `
                             -SinceDate $twoWeeksAgo

# Example 8: Create a draft post with custom title and tags
New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/microsoft/powershell" `
                             -PostTitle "PowerShell Weekly Digest" `
                             -PostStatus "draft" `
                             -Tags @("PowerShell", "Microsoft", "Weekly Digest") `
                             -Categories @("Development", "News")

# Example 9: Just get repository changes without creating a blog post
$changes = Get-GitHubRepositoryChanges -RepositoryUrl "https://github.com/microsoft/powershell"
Write-Host "Repository: $($changes.Repository)"
Write-Host "Changes since: $($changes.SinceDate)"
Write-Host "Commits: $($changes.Commits.Count)"
Write-Host "Pull Requests: $($changes.PullRequests.Count)"
Write-Host "Releases: $($changes.Releases.Count)"

#endregion

#region Batch Processing Examples

# Example 10: Process multiple repositories
$repositories = @(
    "https://github.com/microsoft/powershell",
    "https://github.com/microsoft/vscode",
    "https://github.com/dotnet/core"
)

foreach ($repo in $repositories) {
    Write-Host "Processing repository: $repo" -ForegroundColor Green
    try {
        New-GitHubToWordPressBlogPost -RepositoryUrl $repo -PostStatus "draft" -Verbose
        Write-Host "✓ Successfully processed $repo" -ForegroundColor Green
    }
    catch {
        Write-Warning "✗ Failed to process $repo : $_"
    }
    Start-Sleep -Seconds 2  # Rate limiting
}

#endregion

#region Error Handling Examples

# Example 11: Robust error handling
try {
    $result = New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/microsoft/powershell" -Verbose
    Write-Host "Blog post created successfully!" -ForegroundColor Green
    Write-Host "Post URL: $($result.link)"
    Write-Host "Post ID: $($result.id)"
}
catch {
    Write-Error "Failed to create blog post: $_"
    
    # Check configuration
    $config = Get-GitHubToWordPressConfig
    if (-not $config.GitHubTokenConfigured) {
        Write-Warning "GitHub token is not configured. Use Set-GitHubToWordPressConfig to set it."
    }
    if (-not $config.WordPressConfigured) {
        Write-Warning "WordPress configuration is not set. Use Set-GitHubToWordPressConfig to configure it."
    }
}

#endregion

#region Automation Examples

# Example 12: Scheduled automation script
# This could be run as a scheduled task or cron job
function Invoke-AutomatedBlogUpdate {
    param(
        [string[]]$Repositories,
        [string]$ConfigFile = "./config.json"
    )
    
    # Load configuration
    Set-GitHubToWordPressConfig -ConfigFile $ConfigFile
    
    $successCount = 0
    $errorCount = 0
    
    foreach ($repo in $Repositories) {
        try {
            Write-Host "[$(Get-Date)] Processing $repo..." -ForegroundColor Yellow
            
            # Check if there are actually changes before creating a post
            $changes = Get-GitHubRepositoryChanges -RepositoryUrl $repo
            $totalChanges = $changes.Commits.Count + $changes.PullRequests.Count + $changes.Releases.Count
            
            if ($totalChanges -eq 0) {
                Write-Host "[$(Get-Date)] No changes found for $repo, skipping..." -ForegroundColor Gray
                continue
            }
            
            # Create the blog post
            $post = New-GitHubToWordPressBlogPost -RepositoryUrl $repo
            Write-Host "[$(Get-Date)] ✓ Created post for $repo - $($post.link)" -ForegroundColor Green
            $successCount++
            
            # Rate limiting
            Start-Sleep -Seconds 5
        }
        catch {
            Write-Warning "[$(Get-Date)] ✗ Failed to process $repo : $_"
            $errorCount++
        }
    }
    
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Successful posts: $successCount" -ForegroundColor Green
    Write-Host "Errors: $errorCount" -ForegroundColor Red
}

# Example usage of automated function
# $myRepos = @(
#     "https://github.com/microsoft/powershell",
#     "https://github.com/microsoft/vscode"
# )
# Invoke-AutomatedBlogUpdate -Repositories $myRepos

#endregion

Write-Host "`nExamples loaded! Edit the configuration values and uncomment the examples you want to try." -ForegroundColor Green