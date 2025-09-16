# GitHub to WordPress PowerShell Module
# This module creates WordPress blog posts highlighting changes in GitHub repositories

# Import required modules
if (-not (Get-Module -ListAvailable -Name 'PowerShellForGitHub' -ErrorAction SilentlyContinue)) {
    Write-Warning "PowerShellForGitHub module is recommended for enhanced GitHub API functionality. Install with: Install-Module PowerShellForGitHub"
}

# Module-level variables for configuration
$script:GitHubToken = $null
$script:WordPressConfig = @{}
$script:LastPostTracker = @{}

#region Configuration Functions

<#
.SYNOPSIS
    Sets configuration for GitHub and WordPress integration.

.DESCRIPTION
    Configures the module with necessary credentials and settings for GitHub API and WordPress REST API access.

.PARAMETER GitHubToken
    Personal access token for GitHub API access.

.PARAMETER WordPressUrl
    Base URL of the WordPress site (e.g., https://myblog.com).

.PARAMETER WordPressUsername
    WordPress username for API authentication.

.PARAMETER WordPressPassword
    WordPress application password for API authentication.

.PARAMETER ConfigFile
    Path to a JSON configuration file containing settings.

.EXAMPLE
    Set-GitHubToWordPressConfig -GitHubToken "ghp_xxxx" -WordPressUrl "https://myblog.com" -WordPressUsername "admin" -WordPressPassword "app_password"
#>
function Set-GitHubToWordPressConfig {
    [CmdletBinding()]
    param(
        [string]$GitHubToken,
        [string]$WordPressUrl,
        [string]$WordPressUsername,
        [string]$WordPressPassword,
        [string]$ConfigFile
    )
    
    if ($ConfigFile -and (Test-Path $ConfigFile)) {
        try {
            $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
            $script:GitHubToken = $config.GitHubToken
            $script:WordPressConfig = @{
                Url = $config.WordPressUrl
                Username = $config.WordPressUsername
                Password = $config.WordPressPassword
            }
            Write-Verbose "Configuration loaded from file: $ConfigFile"
        }
        catch {
            Write-Error "Failed to load configuration from file: $_"
            return
        }
    }
    else {
        if ($GitHubToken) { $script:GitHubToken = $GitHubToken }
        if ($WordPressUrl -or $WordPressUsername -or $WordPressPassword) {
            $script:WordPressConfig = @{
                Url = $WordPressUrl
                Username = $WordPressUsername
                Password = $WordPressPassword
            }
        }
    }
    
    Write-Verbose "Configuration updated successfully"
}

<#
.SYNOPSIS
    Gets the current module configuration.

.DESCRIPTION
    Returns the current configuration settings for GitHub and WordPress integration.

.EXAMPLE
    Get-GitHubToWordPressConfig
#>
function Get-GitHubToWordPressConfig {
    [CmdletBinding()]
    param()
    
    return @{
        GitHubTokenConfigured = -not [string]::IsNullOrEmpty($script:GitHubToken)
        WordPressConfigured = $script:WordPressConfig.Count -gt 0
        WordPressUrl = $script:WordPressConfig.Url
        WordPressUsername = $script:WordPressConfig.Username
    }
}

#endregion

#region GitHub Functions

<#
.SYNOPSIS
    Gets changes from a GitHub repository since a specified date.

.DESCRIPTION
    Retrieves commits, pull requests, and releases from a GitHub repository since the last blog post or specified date.

.PARAMETER RepositoryUrl
    URL of the GitHub repository (e.g., https://github.com/owner/repo).

.PARAMETER SinceDate
    Date to retrieve changes since. If not specified, uses the last blog post date.

.PARAMETER Owner
    Repository owner (alternative to RepositoryUrl).

.PARAMETER Repository
    Repository name (alternative to RepositoryUrl).

.EXAMPLE
    Get-GitHubRepositoryChanges -RepositoryUrl "https://github.com/microsoft/powershell"

.EXAMPLE
    Get-GitHubRepositoryChanges -Owner "microsoft" -Repository "powershell" -SinceDate (Get-Date).AddDays(-30)
#>
function Get-GitHubRepositoryChanges {
    [CmdletBinding(DefaultParameterSetName = 'ByUrl')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByUrl')]
        [string]$RepositoryUrl,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByComponents')]
        [string]$Owner,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByComponents')]
        [string]$Repository,
        
        [DateTime]$SinceDate
    )
    
    # Parse repository URL if provided
    if ($PSCmdlet.ParameterSetName -eq 'ByUrl') {
        if ($RepositoryUrl -match 'github\.com[\/:]([^\/]+)\/([^\/\s]+?)(?:\.git)?/?$') {
            $Owner = $Matches[1]
            $Repository = $Matches[2]
        }
        else {
            throw "Invalid GitHub repository URL format: $RepositoryUrl"
        }
    }
    
    # Set default since date if not provided
    if (-not $SinceDate) {
        $repoKey = "$Owner/$Repository"
        if ($script:LastPostTracker.ContainsKey($repoKey)) {
            $SinceDate = $script:LastPostTracker[$repoKey]
        }
        else {
            $SinceDate = (Get-Date).AddDays(-30) # Default to 30 days ago
        }
    }
    
    Write-Verbose "Getting changes for $Owner/$Repository since $($SinceDate.ToString('yyyy-MM-dd'))"
    
    $changes = @{
        Repository = "$Owner/$Repository"
        SinceDate = $SinceDate
        Commits = @()
        PullRequests = @()
        Releases = @()
    }
    
    try {
        # Get commits
        $commits = Get-GitHubCommits -Owner $Owner -Repository $Repository -SinceDate $SinceDate
        $changes.Commits = $commits
        
        # Get pull requests
        $pullRequests = Get-GitHubPullRequests -Owner $Owner -Repository $Repository -SinceDate $SinceDate
        $changes.PullRequests = $pullRequests
        
        # Get releases
        $releases = Get-GitHubReleases -Owner $Owner -Repository $Repository -SinceDate $SinceDate
        $changes.Releases = $releases
        
        Write-Verbose "Found $($commits.Count) commits, $($pullRequests.Count) pull requests, and $($releases.Count) releases"
        
        return $changes
    }
    catch {
        Write-Error "Failed to retrieve GitHub repository changes: $_"
        throw
    }
}

function Get-GitHubCommits {
    param($Owner, $Repository, $SinceDate)
    
    $headers = @{
        'Authorization' = "token $script:GitHubToken"
        'Accept' = 'application/vnd.github.v3+json'
        'User-Agent' = 'GitHubToWordPress-PowerShell/1.0'
    }
    
    $since = $SinceDate.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $uri = "https://api.github.com/repos/$Owner/$Repository/commits?since=$since&per_page=100"
    
    $commits = @()
    do {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop
        $commits += $response
        
        # Check for pagination
        $linkHeader = $response.PSObject.Properties['Link']
        $uri = $null
        if ($linkHeader -and $linkHeader.Value -match 'rel="next"') {
            if ($linkHeader.Value -match '<([^>]+)>;\s*rel="next"') {
                $uri = $Matches[1]
            }
        }
    } while ($uri)
    
    return $commits | Select-Object sha, commit, author, html_url
}

function Get-GitHubPullRequests {
    param($Owner, $Repository, $SinceDate)
    
    $headers = @{
        'Authorization' = "token $script:GitHubToken"
        'Accept' = 'application/vnd.github.v3+json'
        'User-Agent' = 'GitHubToWordPress-PowerShell/1.0'
    }
    
    # Get both open and closed PRs
    $states = @('open', 'closed')
    $allPRs = @()
    
    foreach ($state in $states) {
        $uri = "https://api.github.com/repos/$Owner/$Repository/pulls?state=$state&sort=updated&direction=desc&per_page=100"
        
        do {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop
            $filteredPRs = $response | Where-Object { 
                [DateTime]$_.updated_at -gt $SinceDate 
            }
            $allPRs += $filteredPRs
            
            # Check for pagination and if we've gone beyond our date range
            $linkHeader = $response.PSObject.Properties['Link']
            $uri = $null
            if ($linkHeader -and $linkHeader.Value -match 'rel="next"' -and $filteredPRs.Count -gt 0) {
                if ($linkHeader.Value -match '<([^>]+)>;\s*rel="next"') {
                    $uri = $Matches[1]
                }
            }
        } while ($uri)
    }
    
    return $allPRs | Select-Object number, title, state, created_at, updated_at, merged_at, html_url, user
}

function Get-GitHubReleases {
    param($Owner, $Repository, $SinceDate)
    
    $headers = @{
        'Authorization' = "token $script:GitHubToken"
        'Accept' = 'application/vnd.github.v3+json'
        'User-Agent' = 'GitHubToWordPress-PowerShell/1.0'
    }
    
    $uri = "https://api.github.com/repos/$Owner/$Repository/releases?per_page=100"
    
    $releases = @()
    do {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop
        $filteredReleases = $response | Where-Object { 
            [DateTime]$_.published_at -gt $SinceDate 
        }
        $releases += $filteredReleases
        
        # Check for pagination and if we've gone beyond our date range
        $linkHeader = $response.PSObject.Properties['Link']
        $uri = $null
        if ($linkHeader -and $linkHeader.Value -match 'rel="next"' -and $filteredReleases.Count -gt 0) {
            if ($linkHeader.Value -match '<([^>]+)>;\s*rel="next"') {
                $uri = $Matches[1]
            }
        }
    } while ($uri)
    
    return $releases | Select-Object tag_name, name, published_at, html_url, body, prerelease
}

#endregion

#region WordPress Functions

function New-WordPressBlogPost {
    param(
        [string]$Title,
        [string]$Content,
        [string]$Status = 'publish',
        [string[]]$Tags = @(),
        [string[]]$Categories = @()
    )
    
    $headers = @{
        'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($script:WordPressConfig.Username):$($script:WordPressConfig.Password)"))
        'Content-Type' = 'application/json'
    }
    
    $postData = @{
        title = $Title
        content = $Content
        status = $Status
        tags = $Tags
        categories = $Categories
    }
    
    $uri = "$($script:WordPressConfig.Url.TrimEnd('/'))/wp-json/wp/v2/posts"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($postData | ConvertTo-Json) -ErrorAction Stop
        Write-Verbose "Blog post created successfully with ID: $($response.id)"
        return $response
    }
    catch {
        Write-Error "Failed to create WordPress blog post: $_"
        throw
    }
}

#endregion

#region Blog Post Generation

function Format-GitHubChangesForBlog {
    param($Changes)
    
    $content = @()
    $content += "<h2>Repository Update: $($Changes.Repository)</h2>"
    $content += "<p><em>Changes since $($Changes.SinceDate.ToString('MMMM dd, yyyy'))</em></p>"
    
    # Add releases section
    if ($Changes.Releases.Count -gt 0) {
        $content += "<h3>🚀 New Releases</h3>"
        $content += "<ul>"
        foreach ($release in $Changes.Releases | Sort-Object published_at -Descending | Select-Object -First 5) {
            $releaseDate = [DateTime]$release.published_at
            $preReleaseText = if ($release.prerelease) { " (Pre-release)" } else { "" }
            $content += "<li><strong><a href='$($release.html_url)'>$($release.name)$preReleaseText</a></strong> - $($releaseDate.ToString('MMM dd, yyyy'))</li>"
            if ($release.body) {
                $bodyPreview = ($release.body -split "`n" | Select-Object -First 3) -join " "
                if ($bodyPreview.Length -gt 200) {
                    $bodyPreview = $bodyPreview.Substring(0, 200) + "..."
                }
                $content += "<p><em>$bodyPreview</em></p>"
            }
        }
        $content += "</ul>"
    }
    
    # Add pull requests section
    if ($Changes.PullRequests.Count -gt 0) {
        $mergedPRs = $Changes.PullRequests | Where-Object { $_.state -eq 'closed' -and $_.merged_at }
        if ($mergedPRs.Count -gt 0) {
            $content += "<h3>🔀 Recent Merged Pull Requests</h3>"
            $content += "<ul>"
            foreach ($pr in $mergedPRs | Sort-Object merged_at -Descending | Select-Object -First 10) {
                $mergedDate = [DateTime]$pr.merged_at
                $content += "<li><a href='$($pr.html_url)'>#$($pr.number): $($pr.title)</a> by $($pr.user.login) - $($mergedDate.ToString('MMM dd, yyyy'))</li>"
            }
            $content += "</ul>"
        }
        
        $openPRs = $Changes.PullRequests | Where-Object { $_.state -eq 'open' }
        if ($openPRs.Count -gt 0) {
            $content += "<h3>🔧 Active Pull Requests</h3>"
            $content += "<ul>"
            foreach ($pr in $openPRs | Sort-Object updated_at -Descending | Select-Object -First 5) {
                $updatedDate = [DateTime]$pr.updated_at
                $content += "<li><a href='$($pr.html_url)'>#$($pr.number): $($pr.title)</a> by $($pr.user.login) - Updated $($updatedDate.ToString('MMM dd, yyyy'))</li>"
            }
            $content += "</ul>"
        }
    }
    
    # Add commits section (summarized)
    if ($Changes.Commits.Count -gt 0) {
        $content += "<h3>📝 Recent Activity</h3>"
        $content += "<p>There have been <strong>$($Changes.Commits.Count) commits</strong> to the repository since our last update.</p>"
        
        if ($Changes.Commits.Count -gt 0) {
            $content += "<h4>Latest Commits</h4>"
            $content += "<ul>"
            foreach ($commit in $Changes.Commits | Sort-Object { [DateTime]$_.commit.author.date } -Descending | Select-Object -First 5) {
                $commitDate = [DateTime]$commit.commit.author.date
                $message = $commit.commit.message -split "`n" | Select-Object -First 1
                $content += "<li><a href='$($commit.html_url)'>$message</a> by $($commit.commit.author.name) - $($commitDate.ToString('MMM dd, yyyy'))</li>"
            }
            $content += "</ul>"
        }
    }
    
    # Add footer
    $content += "<hr>"
    $content += "<p><em>This post was automatically generated from GitHub repository activity. Visit the <a href='https://github.com/$($Changes.Repository)'>repository</a> for more details.</em></p>"
    
    return $content -join "`n"
}

#endregion

#region Main Function

<#
.SYNOPSIS
    Creates a new WordPress blog post highlighting changes to a GitHub repository.

.DESCRIPTION
    Analyzes a GitHub repository for changes since the last blog post (or specified date) and creates a new WordPress blog post highlighting the major updates including releases, pull requests, and commits.

.PARAMETER RepositoryUrl
    URL of the GitHub repository to analyze.

.PARAMETER Owner
    Repository owner (alternative to RepositoryUrl).

.PARAMETER Repository
    Repository name (alternative to RepositoryUrl).

.PARAMETER SinceDate
    Date to analyze changes since. If not specified, uses the last blog post date or 30 days ago.

.PARAMETER PostTitle
    Custom title for the blog post. If not specified, generates one automatically.

.PARAMETER PostStatus
    WordPress post status (publish, draft, private). Default is 'publish'.

.PARAMETER Tags
    Array of tags to add to the blog post.

.PARAMETER Categories
    Array of categories to add to the blog post.

.PARAMETER DryRun
    If specified, shows what the blog post would look like without actually creating it.

.EXAMPLE
    New-GitHubToWordPressBlogPost -RepositoryUrl "https://github.com/microsoft/powershell"

.EXAMPLE
    New-GitHubToWordPressBlogPost -Owner "microsoft" -Repository "powershell" -PostTitle "PowerShell Updates" -Tags @("PowerShell", "Microsoft") -DryRun
#>
function New-GitHubToWordPressBlogPost {
    [CmdletBinding(DefaultParameterSetName = 'ByUrl')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByUrl')]
        [string]$RepositoryUrl,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByComponents')]
        [string]$Owner,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ByComponents')]
        [string]$Repository,
        
        [DateTime]$SinceDate,
        [string]$PostTitle,
        [ValidateSet('publish', 'draft', 'private')]
        [string]$PostStatus = 'publish',
        [string[]]$Tags = @(),
        [string[]]$Categories = @(),
        [switch]$DryRun
    )
    
    # Validate configuration
    if ([string]::IsNullOrEmpty($script:GitHubToken)) {
        throw "GitHub token not configured. Use Set-GitHubToWordPressConfig to set credentials."
    }
    
    if (-not $DryRun -and ($script:WordPressConfig.Count -eq 0 -or [string]::IsNullOrEmpty($script:WordPressConfig.Url))) {
        throw "WordPress configuration not set. Use Set-GitHubToWordPressConfig to set WordPress details."
    }
    
    try {
        # Get repository changes
        $getChangesParams = @{}
        if ($PSCmdlet.ParameterSetName -eq 'ByUrl') {
            $getChangesParams.RepositoryUrl = $RepositoryUrl
        }
        else {
            $getChangesParams.Owner = $Owner
            $getChangesParams.Repository = $Repository
        }
        
        if ($SinceDate) {
            $getChangesParams.SinceDate = $SinceDate
        }
        
        Write-Verbose "Retrieving repository changes..."
        $changes = Get-GitHubRepositoryChanges @getChangesParams
        
        # Generate blog post content
        Write-Verbose "Generating blog post content..."
        $content = Format-GitHubChangesForBlog -Changes $changes
        
        # Generate title if not provided
        if ([string]::IsNullOrEmpty($PostTitle)) {
            $PostTitle = "Updates from $($changes.Repository) - $((Get-Date).ToString('MMMM yyyy'))"
        }
        
        # Add default tags
        $defaultTags = @('GitHub', 'Development', 'Updates')
        $allTags = ($Tags + $defaultTags) | Sort-Object -Unique
        
        if ($DryRun) {
            Write-Host "=== DRY RUN - Blog Post Preview ===" -ForegroundColor Yellow
            Write-Host "Title: $PostTitle" -ForegroundColor Green
            Write-Host "Status: $PostStatus" -ForegroundColor Green
            Write-Host "Tags: $($allTags -join ', ')" -ForegroundColor Green
            Write-Host "Categories: $($Categories -join ', ')" -ForegroundColor Green
            Write-Host "`nContent:" -ForegroundColor Green
            Write-Host $content
            Write-Host "`n=== End Preview ===" -ForegroundColor Yellow
            return
        }
        
        # Create the blog post
        Write-Verbose "Creating WordPress blog post..."
        $post = New-WordPressBlogPost -Title $PostTitle -Content $content -Status $PostStatus -Tags $allTags -Categories $Categories
        
        # Update last post tracker
        $repoKey = $changes.Repository
        $script:LastPostTracker[$repoKey] = Get-Date
        
        Write-Host "Successfully created blog post: $($post.link)" -ForegroundColor Green
        return $post
    }
    catch {
        Write-Error "Failed to create GitHub to WordPress blog post: $_"
        throw
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'New-GitHubToWordPressBlogPost',
    'Get-GitHubRepositoryChanges',
    'Set-GitHubToWordPressConfig',
    'Get-GitHubToWordPressConfig'
)