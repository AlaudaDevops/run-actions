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

4. **Prepare template files**
   - Place files to sync in `.github/sync/templates/` directory

## Workflow Features

### Multi-branch Support
- Sync to default branch, specific branches, or branch pattern matching
- Support wildcard patterns like `release-*`, `hotfix-*`

### Repository Filtering
- Exact match for specific repositories
- Regular expression matching for repository names using `regex:` prefix

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

## Configuration Examples

### Basic Configuration

```yaml
# Optional: Customize PR title format
pr_title: "chore: sync security files to"

# Optional: Target branches (defaults to "default")
target_branches: "default"

# Optional: Skip public repositories (defaults to false)
skip_public_repos: false

# Required: Organization name
org_name: "AlaudaDevops"

files:
  - source: ".github/sync/templates/SECURITY.md"
    target: "SECURITY.md"
    description: "Security policy file"
  - source: ".github/sync/templates/.gitignore"
    target: ".gitignore"
    description: "Standard gitignore file"

repositories:
  - "alauda/repo1"
  - "alauda/repo2"
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
3. **Branch Resolution** - Resolve target branches based on patterns (default, specific branches, or wildcards)
4. **File Comparison** - Compare local source files with remote target files to detect differences
5. **PR Creation** - Create Pull Requests only for repositories with file differences
6. **Content Sync** - Clone, copy files, commit changes with descriptive messages, and push to create PRs

## Troubleshooting

- **Config file not found**: Ensure configuration file path is correct
- **Invalid YAML**: Validate configuration file syntax
- **Permission denied**: Check `ORG_REPO_TOKEN` permissions
- **Branch not found**: Verify target branches exist in target repositories
- **No changes detected**: Files are already up to date in target repositories

## Best Practices

1. **Test First**: Use dry run mode to test configuration before actual sync
2. **Progressive Deployment**: Test on a few repositories first, then expand to full organization
3. **File Management**: Keep template files organized in the source locations specified in config
4. **Minimal Permissions**: Only give tokens necessary permissions for target repositories
5. **Configuration Validation**: Ensure YAML syntax is correct before running workflow

## Example Scenarios

### Sync Security Policy to All Repositories
- Config: All repositories' default branches
- Files: `SECURITY.md`, `CODE_OF_CONDUCT.md`

### Update CI Configuration to Release Branches
- Config: `release-*` branch pattern
- Files: `.github/workflows/ci.yml`, `.github/dependabot.yml`

### Sync Governance Files to Service Repositories
- Config: `regex:alauda/service-.*` repository pattern
- Files: `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`
