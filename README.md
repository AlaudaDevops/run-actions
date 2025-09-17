# Run Actions

A collection of GitHub Actions workflows for automated repository management and maintenance.

## Workflows

### Cherry-pick Commits to Branches (`cherry-pick-commit.yml`)

Automates the process of cherry-picking commits to multiple target branches and creating pull requests.

#### Features
- **Multi-branch cherry-picking**: Apply commits to multiple branches simultaneously
- **Pull request creation**: Automatically creates PRs for each target branch
- **Flexible targeting**: Support for any combination of branches
- **Batch processing**: Handle multiple commits in specified order

#### Usage
```bash
gh workflow run cherry-pick-commit.yml \
  -f repository=alaudadevops/my-repo \
  -f commits=abc123,def456,ghi789 \
  -f target_branches=release-1.0,release-1.1,main \
  -f pr_title_prefix="[Hotfix]"
```

### Dependabot Runner (`dependabot.yaml`)

Runs custom dependabot scripts for dependency management across repositories.

#### Features
- **Scheduled execution**: Runs weekly on Mondays at 7 AM UTC
- **Custom scripts**: Execute Python-based dependency management scripts
- **Configurable**: Specify repository, revision, and script to run

#### Default Configuration
- **Repository**: `alaudadevops/hack`
- **Branch**: `main`
- **Script**: `python run-bot.py`

### File Sync (`file-sync.yaml`)

Synchronizes files across multiple repositories in an organization using configuration-driven approach.

#### Features
- **Config-driven**: Uses YAML configuration files to define sync rules
- **Regex support**: Target repositories using regex patterns
- **PR creation**: Automatically creates pull requests with synced changes
- **Dry run mode**: Test sync operations without creating actual PRs

#### Usage
```bash
gh workflow run file-sync.yaml \
  -f config_file=".github/sync/custom-config.yaml" \
  -f repositories="regex:AlaudaDevops/.*" \
  -f dry_run=true
```

### Reverse Sync on Push (`reverse-sync-push.yml`)

Synchronizes changes from a source repository to a target repository, useful for maintaining documentation or shared files.

#### Features
- **Selective sync**: Configure specific paths to sync or ignore
- **Reusable workflow**: Can be called by other workflows
- **Path filtering**: Fine-grained control over what gets synced

#### Default Configuration
- **Ignored paths**: `.github/`, `README.md`
- **Synced paths**: `docs/`, `.yarn/`, config files

### Run Integration Test (`run-integration-test.yaml`)

Executes integration tests in a Kubernetes environment using Kind clusters.

#### Features
- **Kubernetes testing**: Sets up Kind cluster for testing
- **Tool integration**: Includes kubectl and Tekton CLI (tkn)
- **Flexible scripting**: Run custom test scripts
- **Multi-environment**: Support for different repositories and revisions

#### Tools Included
- kubectl (Kubernetes CLI)
- tkn (Tekton CLI)
- Kind (Kubernetes in Docker)

### Setup Alauda Organization Rules (`setup-alauda-org-rules.yaml`)

Applies organizational rules and configurations to specific Alauda repositories.

#### Features
- **Scheduled execution**: Runs weekly on Sundays at midnight
- **Repository-specific**: Targets specific documentation repositories
- **Automated governance**: Ensures consistent repository settings

#### Target Repositories
- devops-docs, devops-pipelines-docs, devops-connectors-docs
- gitlab-docs, harbor-docs, sonarqube-docs, nexus-docs

### Setup Organization Rules (`setup-org-rules.yaml`)

General-purpose organizational rule setup for AlaudaDevops repositories.

#### Features
- **Daily execution**: Runs daily at 6:25 AM UTC
- **Configurable**: Specify repository, branch, and script
- **Organization-wide**: Applies rules across all organization repositories

#### Default Configuration
- **Repository**: `alaudadevops/hack`
- **Branch**: `main`
- **Script**: `./scripts/setup-repos.sh alaudadevops`

### Sync Documentation (`sync-docs-advanced.yml`)

Advanced documentation synchronization between repositories with sophisticated change detection.

#### Features
- **Change detection**: Only syncs when changes are detected
- **Force sync option**: Override change detection when needed
- **Selective path sync**: Configure exactly which paths to synchronize
- **Reusable workflow**: Can be called by other workflows

#### Default Synced Paths
- `docs/` - Documentation files
- `.yarn/` - Yarn configuration
- `doom.config.yml`, `yarn.lock`, `tsconfig.json`, `package.json`, `sites.yaml`

## Required Secrets

All workflows require the following secret to be configured in the repository:

- `TOKEN`: GitHub Personal Access Token with appropriate permissions:
  - `repo` (full repository access)
  - `read:org` (read organization membership)
  - `workflow` (trigger workflows)
  - Additional permissions as needed per workflow


### Manage Stale Pull Requests (`manage-stale-prs.yaml`)

Automatically manages inactive pull requests across an organization by warning, closing, and cleaning up stale branches.

#### Features

- **Multi-stage lifecycle management**: Warning → Close → Delete
- **Configurable timeframes**: Customize warning, closing, and deletion periods
- **Branch protection**: Protect important branches from deletion using wildcard patterns
- **Organization-wide**: Process all repositories in a specified GitHub organization
- **Dry run support**: Test configuration without making actual changes
- **Detailed logging**: Comprehensive reporting of all actions taken

#### Configuration

The workflow supports both scheduled execution and manual triggering with custom parameters:

**Parameters:**
- `organization`: GitHub organization to process (default: "alauda")
- `warning_days`: Days before warning about inactivity (default: 30)
- `close_days`: Days before closing inactive PR (default: 60, must be > warning_days)
- `delete_days`: Days before deleting stale branch (default: 90, must be > close_days)
- `protected_branches_pattern`: Comma-separated patterns to protect (default: "main,release-*,alauda-*")
- `dry_run`: Test mode without making changes (default: false)

**Schedule:**
- Runs daily at 2 AM UTC
- Can be triggered manually via workflow_dispatch

#### Branch Protection

The workflow supports protecting branches from deletion using patterns:
- **Exact matches**: `main`, `develop`
- **Wildcard patterns**: `release-*`, `alauda-*`, `feature-*`
- **Multiple patterns**: Comma-separated list

Protected branches will never be deleted, even after the deletion period.

#### Workflow Process

1. **Validation**: Ensures close_days > warning_days > delete_days
2. **Repository Discovery**: Finds all repositories in the specified organization
3. **PR Analysis**: For each open PR, calculates days since last activity
4. **Action Execution**:
   - **Warning Stage** (after X days): Adds a warning comment explaining the lifecycle
   - **Close Stage** (after Y days): Closes the PR with an explanation comment
   - **Delete Stage** (after Z days): Deletes the branch (if not protected and PR is closed)

#### Usage Examples

**Manual Execution with Custom Parameters:**
```bash
# Via GitHub UI: Actions → Manage Stale Pull Requests → Run workflow
# Or via CLI:
gh workflow run manage-stale-prs.yaml \
  -f organization=myorg \
  -f warning_days=14 \
  -f close_days=30 \
  -f delete_days=45 \
  -f protected_branches_pattern="main,master,release-*,hotfix-*" \
  -f dry_run=true
```

**Scheduled Execution:**
The workflow runs automatically every day at 2 AM UTC using the default parameters.

#### Required Secrets

- `TOKEN`: GitHub Personal Access Token with the following permissions:
  - `repo` (full repository access)
  - `read:org` (read organization membership)
  - `delete_repo` (delete repository branches)

#### Output Example

```
🔍 Managing stale PRs for organization: myorg
📅 Configuration:
  - Warning after: 30 days
  - Close after: 60 days
  - Delete branch after: 90 days
  - Protected branches: main,release-*,alauda-*

🔄 Processing repository: myorg/example-repo
  📋 Found 3 open PR(s)
    🔍 PR #123: "Add new feature"
      📅 Last updated: 45 days ago
      🌿 Branch: feature/new-feature
      👤 Author: developer1
      🔒 Closing inactive PR
      ✅ PR closed and commented

📊 Summary:
  - Repositories processed: 15
  - PRs warned: 5
  - PRs closed: 3
  - Branches deleted: 2
```
