# PowerShell script to manage git tags with version parameter

param(
    [Parameter(Mandatory=$false)]
    [string]$VersionTag,
    
    [switch]$Force,
    [switch]$Help
)

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Get-LatestVersionTag {
    # Get all tags that match semantic versioning pattern
    $tags = git tag -l "v*.*.*" 2>$null | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' }
    
    if (-not $tags) {
        return $null
    }
    
    # Parse and sort tags by semantic version
    $sortedTags = $tags | ForEach-Object {
        if ($_ -match '^v(\d+)\.(\d+)\.(\d+)$') {
            [PSCustomObject]@{
                Tag = $_
                Major = [int]$Matches[1]
                Minor = [int]$Matches[2]
                Patch = [int]$Matches[3]
            }
        }
    } | Sort-Object Major, Minor, Patch -Descending
    
    if ($sortedTags) {
        return $sortedTags[0].Tag
    }
    return $null
}

function Get-IncrementedMinorVersion {
    param([string]$CurrentTag)
    
    if ($CurrentTag -match '^v(\d+)\.(\d+)\.(\d+)$') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $newMinor = $minor + 1
        return "v$major.$newMinor.0"
    }
    
    # Fallback if no valid tag found
    return "v0.1.0"
}

function Get-ChangedYmlFiles {
    param(
        [string]$FromTag,
        [string]$ToRef = "HEAD"
    )
    
    if (-not $FromTag) {
        Write-ColorOutput Yellow "No previous tag found. Checking all yml files in repository..."
        # Get all yml files if no previous tag exists
        $allYmlFiles = git ls-files "*.yml" 2>$null
        if ($allYmlFiles) {
            return $allYmlFiles | Where-Object { $_ -match '\.(yml|yaml)$' }
        }
        return @()
    }
    
    # Get changed files between tag and current commit
    Write-ColorOutput Cyan "Detecting changed files between $FromTag and $ToRef..."
    $changedFiles = git diff --name-only "$FromTag..$ToRef" 2>$null
    
    if (-not $changedFiles) {
        return @()
    }
    
    # Filter for yml/yaml files
    $ymlFiles = $changedFiles | Where-Object { $_ -match '\.(yml|yaml)$' }
    
    return $ymlFiles
}

function Update-YmlVersions {
    param(
        [string[]]$Files,
        [string]$NewVersion
    )
    
    if (-not $Files -or $Files.Count -eq 0) {
        Write-ColorOutput Yellow "No yml files to update."
        return @()
    }
    
    $updatedFiles = @()
    
    foreach ($file in $Files) {
        if (Test-Path $file) {
            # Read the file content
            $content = Get-Content $file -Raw
            
            # Check if file has version comment
            if ($content -match '^# Version: v\d+\.\d+\.\d+') {
                # Update the version
                $oldContent = $content
                $newContent = $content -replace '^# Version: v\d+\.\d+\.\d+', "# Version: $NewVersion"
                
                if ($oldContent -ne $newContent) {
                    # Write the updated content back
                    Set-Content -Path $file -Value $newContent -NoNewline
                    $updatedFiles += $file
                    Write-ColorOutput Green "  Updated version in: $file"
                }
            }
        }
    }
    
    return $updatedFiles
}

function Show-Help {
    Write-Host ""
    Write-ColorOutput Cyan "publish-version.ps1 - Git Tag Management Script"
    Write-Host ""
    Write-ColorOutput Yellow "DESCRIPTION:"
    Write-Host "  Creates and manages version tags in a git repository."
    Write-Host "  This script creates a full version tag (e.g., v1.0.0) and a major"
    Write-Host "  version tag (e.g., v1) pointing to the same commit."
    Write-Host "  If no version is specified, it auto-detects the latest tag and"
    Write-Host "  increments the minor version."
    Write-Host "  Automatically updates version numbers in changed yml/yaml files that"
    Write-Host "  contain '# Version: vX.Y.Z' comments."
    Write-Host ""
    Write-ColorOutput Yellow "SYNTAX:"
    Write-Host "  ./publish-version.ps1 [[-VersionTag] <string>] [[-Force]] [[-Help]]"
    Write-Host ""
    Write-ColorOutput Yellow "PARAMETERS:"
    Write-Host "  -VersionTag <string> (optional)"
    Write-Host "    The version tag to create. If omitted, automatically detects"
    Write-Host "    the latest tag and increments the minor version."
    Write-Host "    Format: vX.Y.Z (e.g., v1.0.0, v1.5.0, v2.0.1)"
    Write-Host ""
    Write-Host "  -Force"
    Write-Host "    Skip confirmation prompt and execute immediately"
    Write-Host ""
    Write-Host "  -Help"
    Write-Host "    Display this help message and exit"
    Write-Host ""
    Write-ColorOutput Yellow "EXAMPLES:"
    Write-Host "  # Auto-detect latest tag and increment minor version:"
    Write-Host "  ./publish-version.ps1"
    Write-Host ""
    Write-Host "  # Auto-detect and increment without confirmation:"
    Write-Host "  ./publish-version.ps1 -Force"
    Write-Host ""
    Write-Host "  # Create specific version tag v1.0.0 with confirmation:"
    Write-Host "  ./publish-version.ps1 -VersionTag v1.0.0"
    Write-Host ""
    Write-Host "  # Create version tag v2.5.1 without confirmation:"
    Write-Host "  ./publish-version.ps1 -VersionTag v2.5.1 -Force"
    Write-Host ""
    Write-Host "  # Display help:"
    Write-Host "  ./publish-version.ps1 -Help"
    Write-Host ""
    Write-ColorOutput Yellow "WHAT THIS SCRIPT DOES:"
    Write-Host "  1. Auto-detects changed yml files and updates their version comments"
    Write-Host "  2. Creates a tag with the specified (or auto-incremented) version"
    Write-Host "  3. Deletes the major version tag locally (e.g., v1)"
    Write-Host "  4. Recreates the major version tag pointing to the new version"
    Write-Host "  5. Pushes both tags to the remote repository"
    Write-Host "  6. Verifies both tags point to the same commit"
    Write-Host ""
}

# Show help if -Help flag is set
if ($Help) {
    Show-Help
    exit 0
}

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-ColorOutput Red "Error: Not in a git repository root directory!"
    exit 1
}

# Auto-detect and increment version if not provided
if ([string]::IsNullOrWhiteSpace($VersionTag)) {
    Write-ColorOutput Cyan "No version specified. Auto-detecting latest tag..."
    
    $latestTag = Get-LatestVersionTag
    if ($latestTag) {
        Write-ColorOutput Green "Latest tag found: $latestTag"
        $VersionTag = Get-IncrementedMinorVersion $latestTag
        Write-ColorOutput Green "New version will be: $VersionTag"
    } else {
        Write-ColorOutput Yellow "No existing version tags found. Starting with v0.1.0"
        $VersionTag = "v0.1.0"
    }
}

# Validate version tag format (should be like v1.0.0, v2.3.1, etc.)
if ($VersionTag -notmatch '^v\d+\.\d+\.\d+$') {
    Write-ColorOutput Red "Error: Version tag must be in format 'vX.Y.Z' (e.g., v1.0.0, v2.5.1)"
    Write-Host ""
    Write-Host "Run './publish-version.ps1 -Help' for more information."
    exit 1
}

# Extract the major version from the version tag (e.g., v1.0.0 -> v1, v2.5.1 -> v2)
$MajorTag = $VersionTag -replace '\.\d+\.\d+$', ''

Write-ColorOutput Cyan "`nVersion tag: $VersionTag"
Write-ColorOutput Cyan "Major tag:   $MajorTag"

# Check if remote exists
$remoteExists = git remote 2>$null
if (-not $remoteExists) {
    Write-ColorOutput Yellow "Warning: No remote repository configured. Tags will only be created locally."
    $remoteAvailable = $false
} else {
    $remoteAvailable = $true
}

# Detect and update changed yml files
Write-ColorOutput Cyan "`nDetecting yml files to update..."
$previousTag = Get-LatestVersionTag
$changedYmlFiles = Get-ChangedYmlFiles -FromTag $previousTag -ToRef "HEAD"

if ($changedYmlFiles -and $changedYmlFiles.Count -gt 0) {
    Write-ColorOutput Cyan "Found $($changedYmlFiles.Count) changed yml file(s)"
    $updatedFiles = Update-YmlVersions -Files $changedYmlFiles -NewVersion $VersionTag
    
    if ($updatedFiles -and $updatedFiles.Count -gt 0) {
        Write-ColorOutput Green "Updated version in $($updatedFiles.Count) file(s)"
        
        # Stage the updated files
        Write-ColorOutput Cyan "Staging updated yml files..."
        foreach ($file in $updatedFiles) {
            git add $file
        }
        
        # Check if there are changes to commit
        $status = git status --porcelain
        if ($status) {
            Write-ColorOutput Cyan "Committing version updates..."
            git commit -m "Update yml file versions to $VersionTag"
            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                Write-ColorOutput Red "Failed to commit version updates"
                exit 1
            }
        }
    } else {
        Write-ColorOutput Yellow "No yml files needed version updates (already at correct version or no version comment found)"
    }
} else {
    Write-ColorOutput Yellow "No changed yml files detected since last tag"
}

# Ask for confirmation unless -Force is used
if (-not $Force) {
    Write-ColorOutput Yellow "`nThis script will:"
    Write-ColorOutput Yellow "  - Create tag $VersionTag from current commit"
    Write-ColorOutput Yellow "  - Delete local and remote tag $MajorTag (if exists)"
    Write-ColorOutput Yellow "  - Recreate tag $MajorTag pointing to $VersionTag"
    if ($remoteAvailable) {
        Write-ColorOutput Yellow "  - Push both tags to remote"
    }
    
    $response = Read-Host "`nDo you want to continue? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-ColorOutput Red "Operation cancelled."
        exit 0
    }
}

# Create version tag from current commit
Write-ColorOutput Yellow "`nCreating tag $VersionTag..."
git tag $VersionTag
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-ColorOutput Red "Failed to create tag $VersionTag"
    exit 1
}

# Delete major tag locally (if it exists)
if (git tag -l $MajorTag) {
    Write-ColorOutput Yellow "Deleting local tag $MajorTag..."
    git tag -d $MajorTag
}

# Delete major tag on remote (if it exists and remote is available)
if ($remoteAvailable) {
    $remoteTagExists = git ls-remote --tags origin $MajorTag 2>$null
    if ($remoteTagExists) {
        Write-ColorOutput Yellow "Deleting remote tag $MajorTag..."
        git push origin --delete $MajorTag 2>$null
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            Write-ColorOutput Red "Failed to delete remote tag $MajorTag"
        }
    }
}

# Recreate major tag pointing to version tag
Write-ColorOutput Yellow "Creating tag $MajorTag from $VersionTag..."
git tag $MajorTag $VersionTag
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-ColorOutput Red "Failed to create tag $MajorTag"
    exit 1
}

# Push tags to remote
if ($remoteAvailable) {
    Write-ColorOutput Yellow "Pushing tags to remote..."
    git push origin $VersionTag
    git push origin $MajorTag
}

# Verification
Write-ColorOutput Green "`n=== Verification ==="
$version_hash = git rev-parse $VersionTag 2>$null
$major_hash = git rev-parse $MajorTag 2>$null

Write-ColorOutput Cyan "$VersionTag commit: $version_hash"
Write-ColorOutput Cyan "$MajorTag commit:   $major_hash"

if ($version_hash -and $major_hash) {
    if ($version_hash -eq $major_hash) {
        Write-ColorOutput Green "SUCCESS: Both tags point to the same commit!"
    } else {
        Write-ColorOutput Red "ERROR: Tags point to different commits!"
    }
} else {
    Write-ColorOutput Red "ERROR: One or both tags not found!"
}

# Show all tags
Write-ColorOutput Green "`nCurrent tags (showing relevant versions):"
git tag -l "v*" | Sort-Object -Descending | ForEach-Object {
    $tag = $_
    $hash = git rev-parse --short $tag 2>$null
    if ($tag -eq $VersionTag -or $tag -eq $MajorTag) {
        Write-ColorOutput Green "  $tag -> $hash (updated)"
    } else {
        Write-ColorOutput Gray "  $tag -> $hash"
    }
}

Write-ColorOutput Green "`nTag operations completed successfully!"
