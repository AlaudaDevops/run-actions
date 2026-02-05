# OpenCode PR Review Workflow

This workflow uses [OpenCode](https://opencode.ai/) to automatically review pull requests from other repositories using GitHub Actions workflow dispatch.

## Features

- 🤖 AI-powered code review with line-specific comments
- 🎯 Configurable review strictness (strict, balanced, lenient)
- 🔄 Supports `workflow_dispatch` and `workflow_call` triggers
- 📊 Commit status integration
- 🧪 Dry-run mode for testing
- 🔌 Optional PR event payload support

## Setup

### 1. Required Secrets

Add these secrets to your repository or organization:

- `TOKEN`: GitHub token with `repo`, `pull_requests:write`, and `issues:write` permissions
- `OPENCODE_API_KEY`: Your AI provider API key (e.g., Anthropic API key for Claude)

### 2. Configure the Model

Edit the `AI_MODEL` environment variable in the workflow file:

```yaml
env:
  AI_MODEL: "anthropic/claude-sonnet-4-20250514"
```

Supported formats: `provider/model` (e.g., `anthropic/claude-sonnet-4-20250514`, `openai/gpt-4`)

## Usage

### Manual Trigger (Workflow Dispatch)

Run the workflow from the Actions tab:

1. Go to **Actions** → **AI PR Review (OpenCode)**
2. Click **Run workflow**
3. Fill in:
   - **repository**: Target repo in `owner/repo` format
   - **pr_number**: Pull request number to review
   - **review_style**: `strict`, `balanced` (default), or `lenient`
   - **dry_run**: Check to test without posting comments

### From Another Workflow (Workflow Call)

Call this workflow from another repository:

```yaml
name: Auto PR Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    uses: alaudadevops/run-actions/.github/workflows/opencode-pr-review.yaml@main
    with:
      repository: ${{ github.repository }}
      pr_number: ${{ github.event.pull_request.number }}
      review_style: balanced
      dry_run: false
    secrets:
      TOKEN: ${{ secrets.GITHUB_TOKEN }}
      OPENCODE_API_KEY: ${{ secrets.OPENCODE_API_KEY }}
```

### Advanced: With PR Event Payload

Pass the full PR event payload for additional context:

```yaml
jobs:
  review:
    uses: alaudadevops/run-actions/.github/workflows/opencode-pr-review.yaml@main
    with:
      repository: ${{ github.repository }}
      pr_number: ${{ github.event.pull_request.number }}
      pr_event_payload: ${{ toJSON(github.event.pull_request) }}
      review_style: balanced
    secrets:
      TOKEN: ${{ secrets.GITHUB_TOKEN }}
      OPENCODE_API_KEY: ${{ secrets.OPENCODE_API_KEY }}
```

## Review Styles

- **strict**: Thorough review, flags any deviation from best practices
- **balanced** (default): Pragmatic approach, focuses on significant issues
- **lenient**: Only critical issues and obvious improvements

## How It Works

1. **Validates** the PR exists and is open
2. **Clones** the target repository and checks out the PR branch
3. **Prepares** a review prompt based on the selected style
4. **Runs OpenCode** to analyze the PR and post inline comments
5. **Updates** commit status with review results
6. **Posts** a summary comment on the PR

## OpenCode Behavior

OpenCode will:

- Review the entire PR diff
- Post inline comments on specific lines with issues
- Provide a summary comment with overall assessment
- Flag issues by severity (critical, error, warning, info)
- Suggest concrete improvements with code examples

## Customization

### Custom Prompts

Modify the "Prepare review prompt" step to customize the review behavior:

```yaml
- name: Prepare review prompt
  run: |
    cat > review_prompt.txt << 'EOF'
    # Your custom review instructions here
    EOF
```

### Different AI Models

Change the `AI_MODEL` environment variable to use different models:

```yaml
env:
  # OpenAI GPT-4
  AI_MODEL: "openai/gpt-4"

  # Or Google Gemini
  AI_MODEL: "google/gemini-pro"
```

Make sure you have the appropriate API key configured in secrets.

## Troubleshooting

### Review Comments Not Appearing

- Ensure the `TOKEN` has sufficient permissions (`pull_requests:write`)
- Check that the PR is still open
- Verify the PR branch is up-to-date

### API Rate Limits

- OpenCode respects GitHub API rate limits
- For high-volume usage, consider using a GitHub App token instead

### Model Errors

- Verify your `OPENCODE_API_KEY` is valid
- Check the model name format: `provider/model`
- Ensure your account has access to the specified model

## Comparison with Kilo Workflow

| Feature | OpenCode | Kilo |
|---------|----------|------|
| Setup complexity | Simple | Moderate |
| Comment format | Native GitHub review | Custom JSON format |
| Line validation | Built-in | Manual |
| Prompt system | Simple text | System + personalized |
| Output format | Direct PR comments | JSON diagnostics |

## Learn More

- [OpenCode Documentation](https://opencode.ai/docs/)
- [OpenCode GitHub Integration](https://opencode.ai/docs/github/)
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
