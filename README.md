# GitHub to WordPress PowerShell Module

A PowerShell module that automatically creates WordPress blog posts highlighting changes and updates from specified GitHub repositories.

## Features

- 🔍 **Repository Analysis**: Automatically analyzes GitHub repositories for commits, pull requests, and releases
- 📝 **Smart Content Generation**: Creates structured blog posts with formatted sections for different types of changes
- 🕒 **Date Tracking**: Remembers when the last blog post was created to avoid duplicate content
- 🔧 **Flexible Configuration**: Supports multiple authentication methods and configuration options
- 🌐 **WordPress Integration**: Uses WordPress REST API for seamless blog post creation
- 📊 **Rich Formatting**: Generates HTML content with proper formatting, links, and organization

## Installation

1. Clone or download this repository
2. Import the module in PowerShell:

```powershell
Import-Module ./GitHubToWordPress.psd1
```

## Quick Start

### 1. Configure Credentials

```powershell
# Set up GitHub and WordPress credentials
Set-GitHubToWordPressConfig -GitHubToken "ghp_your_github_token" `
                           -WordPressUrl "https://yourblog.com" `
                           -WordPressUsername "your_username" `
                           -WordPressPassword "your_app_password"
```

### 2. Create a Blog Post

```powershell
# Create a blog post from a GitHub repository
New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/microsoft/powershell"
```

## Configuration

### GitHub Authentication

You'll need a GitHub Personal Access Token with the following permissions:
- `public_repo` (for public repositories)
- `repo` (if you need access to private repositories)

Create a token at: https://github.com/settings/tokens

### WordPress Authentication

The module uses WordPress Application Passwords for authentication:

1. Go to your WordPress admin dashboard
2. Navigate to Users → Profile
3. Scroll down to "Application Passwords"
4. Create a new application password
5. Use your WordPress username and the generated application password

### Configuration Methods

#### Method 1: Direct Parameters
```powershell
Set-GitHubToWordPressConfig -GitHubToken "ghp_xxxx" `
                           -WordPressUrl "https://myblog.com" `
                           -WordPressUsername "admin" `
                           -WordPressPassword "xxxx xxxx xxxx xxxx"
```

#### Method 2: Configuration File
Create a JSON configuration file:

```json
{
    "GitHubToken": "ghp_your_token_here",
    "WordPressUrl": "https://yourblog.com",
    "WordPressUsername": "your_username",
    "WordPressPassword": "your_app_password"
}
```

Then load it:
```powershell
Set-GitHubToWordPressConfig -ConfigFile "./config.json"
```

## Usage Examples

### Basic Usage

```powershell
# Analyze a repository and create a blog post
New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/owner/repo"
```

### Custom Date Range

```powershell
# Get changes since a specific date
$sinceDate = (Get-Date).AddDays(-14)
New-GitHubToWordPressBlogPost -Owner "microsoft" -Repository "powershell" -SinceDate $sinceDate
```

### Preview Mode (Dry Run)

```powershell
# See what the blog post would look like without publishing
New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/owner/repo" -DryRun
```

### Custom Formatting

```powershell
# Create a draft post with custom title and tags
New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/owner/repo" `
                             -PostTitle "Weekly Updates from My Project" `
                             -PostStatus "draft" `
                             -Tags @("Development", "Weekly Update") `
                             -Categories @("Tech News")
```

### Get Repository Changes Only

```powershell
# Just retrieve the changes without creating a blog post
$changes = Get-GitHubRepositoryChanges -RepositoryUrl "https://github.com/owner/repo"
Write-Host "Found $($changes.Commits.Count) commits and $($changes.Releases.Count) releases"
```

## Available Functions

### `New-GitHubToWordPressBlogPost`
Creates a new WordPress blog post highlighting GitHub repository changes.

**Parameters:**
- `RepositoryUrl` - GitHub repository URL
- `Owner` / `Repository` - Alternative way to specify repository
- `SinceDate` - Date to analyze changes since
- `PostTitle` - Custom blog post title
- `PostStatus` - WordPress post status (publish, draft, private)
- `Tags` - Array of tags for the post
- `Categories` - Array of categories for the post
- `DryRun` - Preview mode without publishing

### `Get-GitHubRepositoryChanges`
Retrieves changes from a GitHub repository since a specified date.

### `Set-GitHubToWordPressConfig`
Configures GitHub and WordPress credentials and settings.

### `Get-GitHubToWordPressConfig`
Returns current configuration status.

## Blog Post Structure

The generated blog posts include the following sections:

1. **🚀 New Releases** - Recent releases with descriptions
2. **🔀 Recent Merged Pull Requests** - Successfully merged PRs
3. **🔧 Active Pull Requests** - Open PRs still under review
4. **📝 Recent Activity** - Summary of commits and latest changes

## Requirements

- PowerShell 5.1 or later (Windows PowerShell or PowerShell Core)
- Internet connectivity for GitHub and WordPress API access
- GitHub Personal Access Token
- WordPress site with REST API enabled
- WordPress Application Password

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify your GitHub token has the correct permissions
   - Ensure WordPress Application Password is correct
   - Check that WordPress REST API is enabled

2. **No Changes Found**
   - Verify the repository URL is correct
   - Check the date range being analyzed
   - Ensure the repository has recent activity

3. **WordPress Publishing Errors**
   - Verify WordPress URL is correct and accessible
   - Check that your WordPress user has publishing permissions
   - Ensure Application Passwords are enabled in WordPress

### Debug Mode

Enable verbose output to see detailed operation information:

```powershell
New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/owner/repo" -Verbose
```

## License

This project is provided as-is under the MIT License. See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.
