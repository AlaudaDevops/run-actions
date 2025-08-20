# File Sync Workflow

This directory contains GitHub Actions workflows and configuration for synchronizing files across multiple repositories in the organization.

## Directory Structure

```
.github/sync/
├── README.md                    # This file, workflow documentation
├── config/
│   └── sync-config.yaml        # Sync configuration file
├── templates/                   # Template files directory
│   ├── CODE_OF_CONDUCT.md
│   ├── SECURITY.md
│   ├── .gitignore
│   └── dependabot.yml
└── docs/
    └── examples/               # Configuration examples
```

## Quick Start

1. **Workflow is already in place**
   - The workflow file is located at `.github/workflows/file-sync.yaml`

2. **Adjust configuration as needed**
   - Edit `.github/sync/config/sync-config.yaml`

3. **Configure required Secrets**
   - `TOKEN`: GitHub token with repository access

4. **Prepare source repositories**
   - Set up centralized template repositories with files to sync
   - Configure source repositories and branches in your sync configuration

## Workflow Features

### Multi-branch Support
- Sync to default branch, specific branches, or branch pattern matching
- Support wildcard patterns like `release-*`, `hotfix-*`

### Repository Filtering
- Exact match for specific repositories
- Regular expression matching for repository names using `regex:` prefix

### Multi-Source Repository Support
- Sync files from centralized template repositories (recommended approach)
- Support for syncing from different source repositories and branches
- Intelligent caching - same source repositories are cloned only once
- Fallback support for current repository files when needed

### Smart Sync
- Content comparison - only creates PRs when files actually differ
- Dry run mode - preview operations without actually executing

## Configuration Options

### Pull Request Title

You can customize the PR title format using the `pr_title` field:

```yaml
pr_title: "chore: sync security files to"
```

- **Optional**: If not specified, defaults to `"chore: sync files to branch"`
- **Format**: The final PR title will be `"<pr_title> `<branch_name>`"`
- **Example**: `"chore: sync security files to `main`"`

### Target Branches

You can specify which branches to target using the `target_branches` field:

```yaml
target_branches: "main,develop,release-*"
```

- **Optional**: If not specified, defaults to `"default"` (uses each repository's default branch)
- **Format**: Comma-separated list of branch names or patterns
- **Examples**:
  - `"default"` - Only sync to default branch
  - `"main"` - Only sync to main branch
  - `"main,develop"` - Sync to both main and develop branches
  - `"release-*"` - Sync to all branches starting with release-
  - `"main,release-*,hotfix-*"` - Sync to main and all release/hotfix branches

### Skip Public Repositories

You can skip all public repositories using the `skip_public_repos` field:

```yaml
skip_public_repos: true
```

- **Optional**: If not specified, defaults to `false` (includes all repositories)
- **Usage**: When set to `true`, only private and internal repositories will be processed
- **Purpose**: Useful for syncing sensitive files that should not be in public repositories

### Organization Name

You must specify the GitHub organization name using the `org_name` field:

```yaml
org_name: "AlaudaDevops"
```

- **Required**: This field must be specified in the configuration file
- **Usage**: Defines which GitHub organization to sync files to
- **Example**: `"AlaudaDevops"`, `"your-org-name"`

### File Source Configuration

Each file in the `files` array supports the following options:

```yaml
files:
  - source: "path/to/source/file"        # Required: path to source file
    target: "path/to/target/file"        # Required: path in target repositories
    source_repo: "owner/repository"      # Optional: source repository (defaults to current)
    source_branch: "main"                # Optional: source branch (defaults to "main")
    description: "File description"      # Optional: description of the file
```

#### Source Repository Options

- **External Repository** (recommended): Specify `source_repo` in `"owner/repository"` format to sync from centralized template repositories
- **Source Branch**: Use `source_branch` to specify which branch to sync from (defaults to `"main"`)
- **Current Repository** (fallback): If `source_repo` is not specified or set to `"current"`, files are synced from the current repository

#### Performance Optimization

The workflow automatically optimizes repository cloning:
- Repositories with the same `source_repo` + `source_branch` combination are cloned only once
- Multiple files from the same source repository reuse the same clone
- This significantly improves performance when syncing many files from external repositories

## Configuration Examples

### Recommended Configuration (External Repositories)

```yaml
# Optional: Customize PR title format
pr_title: "chore: sync files from templates to"

# Optional: Target branches (defaults to "default")
target_branches: "default"

# Optional: Skip public repositories (defaults to false)
skip_public_repos: false

# Required: Organization name
org_name: "AlaudaDevops"

files:
  # Files from centralized template repositories (recommended approach)
  - source: "templates/SECURITY.md"
    target: "SECURITY.md"
    source_repo: "AlaudaDevops/org-templates"
    source_branch: "main"
    description: "Security policy from org templates"

  - source: "configs/.gitignore"
    target: ".gitignore"
    source_repo: "AlaudaDevops/config-templates"
    source_branch: "main"
    description: "Standard gitignore from config templates"

repositories:
  - "AlaudaDevops/repo1"
  - "AlaudaDevops/repo2"
```

### Advanced Multi-Source Configuration

```yaml
# Optional: Customize PR title format
pr_title: "chore: sync files from multiple sources to"

# Optional: Target branches
target_branches: "main,release-*"

# Optional: Skip public repositories
skip_public_repos: true

# Required: Organization name
org_name: "AlaudaDevops"

files:
  # Files from external template repositories (recommended approach)
  - source: "pipelines/pr-manage.yaml"
    target: ".tekton/pr-manage.yaml"
    source_repo: "AlaudaDevops/tekton-templates"
    source_branch: "main"
    description: "PR management pipeline from tekton templates"

  - source: "templates/Makefile"
    target: "Makefile"
    source_repo: "AlaudaDevops/build-templates"
    source_branch: "main"
    description: "Standard Makefile from build templates"

  - source: ".github/workflows/ci.yaml"
    target: ".github/workflows/ci.yaml"
    source_repo: "AlaudaDevops/workflow-templates"
    source_branch: "v2.0"
    description: "CI workflow from workflow templates v2.0"

  # Multiple files from same external repository (cloned only once)
  - source: "scripts/build.sh"
    target: "scripts/build.sh"
    source_repo: "AlaudaDevops/build-templates"
    source_branch: "main"
    description: "Build script from build templates"

  - source: "scripts/test.sh"
    target: "scripts/test.sh"
    source_repo: "AlaudaDevops/build-templates"
    source_branch: "main"
    description: "Test script from build templates"

  # Fallback: file from current repository (when needed)
  # - source: ".tekton/custom-pipeline.yaml"
  #   target: ".tekton/custom-pipeline.yaml"
  #   description: "Custom pipeline specific to this repo"

repositories:
  - "regex:AlaudaDevops/.*"
```

### Regular Expression Repository Matching

```yaml
# Optional: Customize PR title format
pr_title: "feat: add standard templates to"

# Sync to multiple branch patterns
target_branches: "main,release-*,hotfix-*"

# Skip public repositories for sensitive files
skip_public_repos: true

# Required: Organization name
org_name: "AlaudaDevops"

repositories:
  # Exact matches
  - "alauda/backend-service"

  # Regular expression matching (use regex: prefix)
  - "regex:alauda/service-.*"        # All repos starting with service-
  - "regex:alauda/.*-backend"        # All repos ending with -backend
  - "regex:alauda/app-[0-9]+"        # Match app-1, app-2, etc.
```


## Usage

### Manual Execution

1. Go to Actions → "Sync files to org repositories"
2. Click "Run workflow"
3. Configure parameters:
   - **Config file path**: Configuration file path (default: `.github/sync/config/sync-manage-pr-config.yaml`)
   - **Dry run**: Preview mode (shows what would be synced without creating PRs)

**Note**: Target branches and skip public repositories settings are now configured in the YAML configuration file, not as workflow inputs.

### Branch Pattern Examples

- `default` - Only sync to default branch
- `main` - Only sync to main branch
- `main,develop` - Sync to both main and develop branches
- `release-*` - Sync to all branches starting with release-
- `main,release-*,hotfix-*` - Sync to main and all release/hotfix branches


## Workflow Process

1. **Load Configuration** - Validate and load sync configuration YAML file
2. **Repository Discovery** - Get target repository list from organization (supports exact match and regex patterns)
3. **Source Repository Cloning** - Intelligently clone external source repositories (with caching to avoid duplicates)
4. **Branch Resolution** - Resolve target branches based on patterns (default, specific branches, or wildcards)
5. **File Comparison** - Compare source files (from current or external repos) with remote target files to detect differences
6. **PR Creation** - Create Pull Requests only for repositories with file differences
7. **Content Sync** - Clone target repos, copy files from source locations, commit changes with descriptive messages, and push to create PRs

## Troubleshooting

- **Config file not found**: Ensure configuration file path is correct
- **Invalid YAML**: Validate configuration file syntax
- **Permission denied**: Check `TOKEN` permissions for both target and source repositories
- **Source repository access denied**: Ensure token has access to external source repositories
- **Source branch not found**: Verify source branches exist in source repositories
- **Source file not found**: Check source file paths in source repositories
- **Target branch not found**: Verify target branches exist in target repositories
- **No changes detected**: Files are already up to date in target repositories

## Best Practices

1. **Test First**: Use dry run mode to test configuration before actual sync
2. **Progressive Deployment**: Test on a few repositories first, then expand to full organization
3. **File Management**: Keep template files organized in the source locations specified in config
4. **Minimal Permissions**: Only give tokens necessary permissions for target repositories
5. **Configuration Validation**: Ensure YAML syntax is correct before running workflow

## Example Scenarios

### Sync Security Policy to All Repositories (Current Repository)
- Config: All repositories' default branches
- Files: `SECURITY.md`, `CODE_OF_CONDUCT.md` from current repository

### Update CI Configuration to Release Branches (External Repository)
- Config: `release-*` branch pattern
- Files: `.github/workflows/ci.yml` from `AlaudaDevops/workflow-templates`
- Files: `.github/dependabot.yml` from `AlaudaDevops/config-templates`

### Sync Build Configuration from Centralized Templates
- Config: All service repositories (`regex:AlaudaDevops/service-.*`)
- Files: `Makefile`, `scripts/build.sh`, `scripts/test.sh` from `AlaudaDevops/build-templates:main`
- Files: `Dockerfile` from `AlaudaDevops/docker-templates:v2.0`

### Mix Current and External Repository Files
- Config: All repositories' default branches
- Files: `SECURITY.md` from current repository (organization-specific policy)
- Files: `.github/workflows/ci.yml` from `AlaudaDevops/workflow-templates:main` (standardized CI)
- Files: `Makefile` from `AlaudaDevops/build-templates:main` (standardized build process)
