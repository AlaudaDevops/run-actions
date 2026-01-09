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

### Kilo PR Review (`kilo-pr-review.yaml`)

AI-powered code review for pull requests using [Kilo Code CLI](https://kilo.ai).

#### Features

- **AI Code Review**: Automated code review using Kilo CLI with configurable AI models
- **Shared Prompt**: Centralized review guidelines in this repository
- **Personalized Prompts**: Repository-specific review rules per project
- **Comment Management**: Creates or updates a single review comment (no spam)
- **PR Review Submission**: Submits formal GitHub PR review
- **Dry Run Mode**: Test the review without posting comments
- **Multiple Review Styles**: Strict, balanced, or lenient review approach

#### Prompts

The review uses a two-tier prompt system:

1. **Shared Prompt** (`.github/prompts/pr-review-shared.md` in this repo):
   - Common review guidelines for all repositories
   - Code quality, security, performance, and best practices

2. **Personalized Prompt** (`.github/prompts/pr-review.md` in target repo):
   - Repository-specific guidelines
   - Project conventions, tech stack, and custom rules
   - Optional - falls back to shared prompt only if not present

#### Usage

**Trigger from run-actions repository:**
```bash
gh workflow run kilo-pr-review.yaml \
  --repo alaudadevops/run-actions \
  -f repository="alaudadevops/my-project" \
  -f pr_number="123" \
  -f model="anthropic/claude-sonnet-4-20250514" \
  -f review_style="balanced" \
  -f dry_run=false
```

**Add to your repository:**

Copy the example workflow from `.github/examples/trigger-kilo-review.yaml` to your repository's `.github/workflows/kilo-review.yaml`:

```yaml
# .github/workflows/kilo-review.yaml
name: Kilo PR Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  trigger-review:
    runs-on: ubuntu-latest
    if: github.event.pull_request.draft != true
    steps:
      - name: Trigger Kilo PR Review
        run: |
          gh workflow run kilo-pr-review.yaml \
            --repo alaudadevops/run-actions \
            --field repository="${{ github.repository }}" \
            --field pr_number="${{ github.event.pull_request.number }}" \
            --field model="anthropic/claude-sonnet-4-20250514" \
            --field review_style="balanced"
        env:
          GH_TOKEN: ${{ secrets.RUN_ACTIONS_TOKEN }}
```

**Add a personalized prompt to your repository:**

Create `.github/prompts/pr-review.md` in your repository with project-specific guidelines. See `.github/examples/pr-review-personalized.md` for a template.

#### Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `repository` | Target repository (owner/repo) | Required |
| `pr_number` | Pull request number | Required |
| `model` | AI model to use | `anthropic/claude-sonnet-4-20250514` |
| `review_style` | Review strictness (strict/balanced/lenient) | `balanced` |
| `dry_run` | Test mode without posting comments | `false` |

#### Required Secrets

- `TOKEN`: GitHub token with repo access to target repositories
- `KILO_API_KEY`: API key for the AI provider (e.g., Anthropic API key)
- `RUN_ACTIONS_TOKEN` (in your repo): Token to trigger workflows in run-actions

#### On-Demand Review via Comment

Using the alternative workflow (`.github/examples/trigger-kilo-review-dispatch.yaml`), you can trigger reviews by commenting on a PR:

```
/kilo-review
/kilo-review --style strict
/kilo-review --model anthropic/claude-sonnet-4-20250514 --style lenient
```

## Claude Code Review Skill

A Claude Code skill for performing comprehensive code reviews that outputs structured feedback for GitHub PRs.

### Overview

This skill is designed to be used with [Claude Code](https://github.com/anthropics/claude-code) to review pull requests and generate:

1. **`pr-overview.md`** - A summary comment to post on the PR
2. **`pr-comments.json`** - Inline review comments in [reviewdog rdjson format](https://github.com/reviewdog/reviewdog/tree/master/proto/rdf)

### Prompt Files

| File | Purpose |
|------|---------|
| `.github/prompts/code-review.md` | Main skill prompt with review guidelines and output formats |
| `.github/prompts/code-review-personalized.example.md` | Template for repository-specific customization |

### Usage with Claude Code

1. **Get the PR diff:**
```bash
gh pr diff <PR_NUMBER> > pr-diff.patch
```

2. **Run the review with Claude Code:**
```bash
claude --print "Review this PR diff using the guidelines from .github/prompts/code-review.md:

$(cat pr-diff.patch)"
```

3. **Post the overview comment:**
```bash
gh pr comment <PR_NUMBER> --body-file pr-overview.md
```

4. **Post inline comments using reviewdog:**
```bash
cat pr-comments.json | reviewdog -f=rdjson -reporter=github-pr-review
```

### Output Formats

#### pr-overview.md

A markdown summary with:
- Brief assessment of the PR
- Statistics (critical issues, warnings, suggestions)
- Categorized list of issues with file:line references
- Positive feedback on well-written code

#### pr-comments.json

A JSON file in reviewdog rdjson format:

```json
{
  "source": {
    "name": "claude-code-review",
    "url": "https://github.com/alaudadevops/run-actions"
  },
  "diagnostics": [
    {
      "message": "Potential SQL injection vulnerability",
      "location": {
        "path": "src/db/queries.ts",
        "range": {
          "start": { "line": 42, "column": 1 },
          "end": { "line": 42, "column": 80 }
        }
      },
      "severity": "ERROR",
      "code": {
        "value": "security/sql-injection"
      },
      "suggestions": [
        {
          "text": "const result = await db.query('SELECT * FROM users WHERE id = $1', [userId]);"
        }
      ]
    }
  ]
}
```

### Severity Levels

| Level | Usage |
|-------|-------|
| `ERROR` | Critical issues (security, bugs, breaking changes) - must fix before merge |
| `WARNING` | Should fix but not blocking |
| `INFO` | Suggestions for improvement |
| `HINT` | Minor style/convention suggestions |

### Issue Categories

- `security/*` - Security vulnerabilities (xss, sql-injection, secrets)
- `bug/*` - Potential bugs (null-pointer, race-condition, off-by-one)
- `performance/*` - Performance issues (n-plus-one, memory-leak)
- `style/*` - Style issues (naming, formatting)
- `refactor/*` - Refactoring suggestions (duplication, complexity)
- `docs/*` - Documentation issues (missing, outdated)
- `test/*` - Testing issues (missing, coverage)

### Customization

Create `.github/prompts/code-review.md` in your repository (copy from `code-review-personalized.example.md`) to add:

- Project-specific tech stack details
- Custom naming conventions
- Security requirements
- Performance guidelines
- Testing requirements
- Patterns to ignore

### Integration with GitHub Actions

You can automate the review process with a GitHub Action:

```yaml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Get PR diff
        run: gh pr diff ${{ github.event.pull_request.number }} > pr-diff.patch
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Run Claude Code review
        run: |
          # Run claude code review (requires ANTHROPIC_API_KEY)
          claude --print "Review this PR using .github/prompts/code-review.md guidelines:

          $(cat pr-diff.patch)" > review-output.md
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Post overview comment
        if: always()
        run: |
          if [ -f pr-overview.md ]; then
            gh pr comment ${{ github.event.pull_request.number }} --body-file pr-overview.md
          fi
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Post inline comments
        if: always()
        run: |
          if [ -f pr-comments.json ]; then
            cat pr-comments.json | reviewdog -f=rdjson -reporter=github-pr-review
          fi
        env:
          REVIEWDOG_GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

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
