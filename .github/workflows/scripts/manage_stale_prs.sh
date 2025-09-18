#!/bin/bash

set -euo pipefail

ORGANIZATION="$1"
WARNING_DAYS="$2"
CLOSE_DAYS="$3"
DELETE_DAYS="$4"
PROTECTED_BRANCHES="$5"
DRY_RUN="$6"

echo "🔍 Managing stale PRs for organization: $ORGANIZATION"
echo "📅 Configuration:"
echo "  - Warning after: $WARNING_DAYS days"
echo "  - Close after: $CLOSE_DAYS days"
echo "  - Delete branch after: $DELETE_DAYS days"
echo "  - Protected branches: $PROTECTED_BRANCHES"
echo "  - Dry run: $DRY_RUN"
echo ""

# Convert protected branches to patterns
IFS=',' read -ra PROTECTED_PATTERNS <<< "$PROTECTED_BRANCHES"

# Function to check if branch matches any protected pattern
is_branch_protected() {
    local branch="$1"
    for pattern in "${PROTECTED_PATTERNS[@]}"; do
        pattern=$(echo "$pattern" | xargs) # trim whitespace
        if [[ "$pattern" == *"*"* ]]; then
            # Handle wildcard patterns
            pattern_regex=$(echo "$pattern" | sed 's/\*/.*/')
            if [[ "$branch" =~ ^${pattern_regex}$ ]]; then
                return 0
            fi
        else
            # Exact match
            if [[ "$branch" == "$pattern" ]]; then
                return 0
            fi
        fi
        done
    return 1
}

# Get all repositories in the organization
echo "🔍 Fetching repositories from organization: $ORGANIZATION"
repos=$(gh repo list "$ORGANIZATION" --limit 1000 --json name,owner,visibility,isArchived -q '.[] | select(.isArchived != true) | .name')

if [ -z "$repos" ]; then
    echo "⚠️  No repositories found in organization: $ORGANIZATION"
    exit 0
fi

repo_count=$(echo "$repos" | wc -l)
echo "📊 Found $repo_count repositories"
echo ""

processed_count=0
warning_count=0
closed_count=0
deleted_count=0

# Process each repository
while IFS= read -r repo; do
    if [ -z "$repo" ]; then
        continue
    fi

    echo "🔄 Processing repository: $ORGANIZATION/$repo"
    processed_count=$((processed_count + 1))

    # Get all open pull requests
    prs=$(gh pr list --repo "$ORGANIZATION/$repo" --limit 1000 --json number,title,createdAt,updatedAt,headRefName,author --jq '.[] | @json')

    if [ -z "$prs" ]; then
        echo "  ℹ️  No open PRs found"
        echo ""
        continue
    fi

    pr_count=$(echo "$prs" | wc -l)
    echo "  📋 Found $pr_count open PR(s)"

    # Process each PR
    while IFS= read -r pr_json; do
        if [ -z "$pr_json" ]; then
            continue
        fi

        pr_number=$(echo "$pr_json" | jq -r '.number')
        pr_title=$(echo "$pr_json" | jq -r '.title')
        pr_created=$(echo "$pr_json" | jq -r '.createdAt')
        pr_updated=$(echo "$pr_json" | jq -r '.updatedAt')
        pr_branch=$(echo "$pr_json" | jq -r '.headRefName')
        pr_author=$(echo "$pr_json" | jq -r '.author.login')

        # Calculate days since last update
        current_date=$(date +%s)
        updated_date=$(date -d "$pr_updated" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$pr_updated" +%s 2>/dev/null || echo "$current_date")
        days_inactive=$(( (current_date - updated_date) / 86400 ))

        echo "    🔍 PR #$pr_number: \"$pr_title\""
        echo "      📅 Last updated: $days_inactive days ago"
        echo "      🌿 Branch: $pr_branch"
        echo "      👤 Author: $pr_author"

        # Check if branch is protected
        if is_branch_protected "$pr_branch"; then
            echo "      🛡️  Branch is protected - skipping deletion rules"
            branch_protected=true
        else
            branch_protected=false
        fi

        # Determine action based on days inactive
        if [ "$days_inactive" -ge "$DELETE_DAYS" ] && [ "$branch_protected" = false ]; then
            # Delete stale branch (only if PR was already closed)
            pr_data=$(gh pr view "$pr_number" --repo "$ORGANIZATION/$repo" --json state,headRepositoryOwner)
            pr_state=$(echo "$pr_data" | jq -r '.state')
            pr_head_repository_owner=$(echo "$pr_data" | jq -r '.headRepositoryOwner.login')
            if [ "$pr_state" = "CLOSED" ] && [ "$pr_head_repository_owner" = "$ORGANIZATION" ]; then
                echo "      🗑️  Branch is stale and PR is closed - deleting branch"
                if [ "$DRY_RUN" = "false" ]; then
                    if gh api --method DELETE "/repos/$ORGANIZATION/$repo/git/refs/heads/$pr_branch" 2>/dev/null; then
                        echo "      ✅ Branch deleted successfully"
                        deleted_count=$((deleted_count + 1))
                    else
                        echo "      ❌ Failed to delete branch (may not exist or insufficient permissions)"
                    fi
                else
                    echo "      🔍 [DRY RUN] Would delete branch: $pr_branch"
                    deleted_count=$((deleted_count + 1))
                fi
            elif [ "$pr_head_repository_owner" != "$ORGANIZATION" ]; then
                echo "      ❌ PR is from a forked repository, skipping branch deletion"
            else
                echo "      ⏳ PR is still open, will close first"
            fi
        fi

        if [ "$days_inactive" -ge "$CLOSE_DAYS" ]; then
            # Close inactive PR
            pr_state=$(gh pr view "$pr_number" --repo "$ORGANIZATION/$repo" --json state --jq '.state')
            if [ "$pr_state" = "OPEN" ]; then
                echo "      🔒 Closing inactive PR"
                close_comment="This pull request has been automatically closed due to inactivity (no updates for $days_inactive days).

If you believe this PR should remain open, please:
1. Add new commits or comments to show continued activity
2. Re-open the PR if needed

The branch will be automatically deleted after $DELETE_DAYS days of total inactivity unless it matches a protected pattern.

Protected branch patterns: \`$PROTECTED_BRANCHES\`"

                if [ "$DRY_RUN" = "false" ]; then
                    gh pr comment "$pr_number" --repo "$ORGANIZATION/$repo" --body "$close_comment"
                    gh pr close "$pr_number" --repo "$ORGANIZATION/$repo"
                    echo "      ✅ PR closed and commented"
                    closed_count=$((closed_count + 1))
                else
                    echo "      🔍 [DRY RUN] Would close PR with comment"
                    closed_count=$((closed_count + 1))
                fi
            fi
        elif [ "$days_inactive" -ge "$WARNING_DAYS" ]; then
            # Add warning comment
            echo "      ⚠️  Adding inactivity warning"

            # Check if warning comment already exists
            existing_warning=$(gh pr view "$pr_number" --repo "$ORGANIZATION/$repo" --json comments --jq '.comments[] | select(.body | contains("🚨 Stale Pull Request Warning")) | .id' | head -1)

            if [ -z "$existing_warning" ]; then
                warning_comment="🚨 **Stale Pull Request Warning**

This pull request has been inactive for $days_inactive days.

**Automated Actions Schedule:**
- ⚠️  **Warning**: After $WARNING_DAYS days (now)
- 🔒 **Auto-close**: After $CLOSE_DAYS days
- 🗑️  **Branch deletion**: After $DELETE_DAYS days (if not protected)

**To keep this PR active:**
- Add new commits
- Reply to this comment
- Request reviews

**Protected branches** (won't be deleted): \`$PROTECTED_BRANCHES\`

_This is an automated message. Reply to this comment to reset the inactivity timer._"

                if [ "$DRY_RUN" = "false" ]; then
                    gh pr comment "$pr_number" --repo "$ORGANIZATION/$repo" --body "$warning_comment"
                    echo "      ✅ Warning comment added"
                    warning_count=$((warning_count + 1))
                else
                    echo "      🔍 [DRY RUN] Would add warning comment"
                    warning_count=$((warning_count + 1))
                fi
            else
                echo "      ℹ️  Warning comment already exists"
            fi
        else
            echo "      ✅ PR is active (within $WARNING_DAYS days)"
        fi

    echo ""
    done <<< "$prs"

echo ""
done <<< "$repos"

echo "📊 Summary:"
echo "  - Repositories processed: $processed_count"
echo "  - PRs warned: $warning_count"
echo "  - PRs closed: $closed_count"
echo "  - Branches deleted: $deleted_count"

if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "🔍 This was a dry run - no actual changes were made"
fi

# Generate GitHub Step Summary if available
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo "## 📊 Stale PR Management Summary"
        echo ""
        echo "| Metric | Count |"
        echo "|--------|-------|"
        echo "| Repositories processed | $processed_count |"
        echo "| PRs warned | $warning_count |"
        echo "| PRs closed | $closed_count |"
        echo "| Branches deleted | $deleted_count |"
        echo ""
        echo "### Configuration"
        echo "- **Organization**: $ORGANIZATION"
        echo "- **Warning after**: $WARNING_DAYS days"
        echo "- **Close after**: $CLOSE_DAYS days"
        echo "- **Delete branch after**: $DELETE_DAYS days"
        echo "- **Protected branches**: \`$PROTECTED_BRANCHES\`"
        echo "- **Dry run**: $DRY_RUN"
        echo ""
        if [ "$DRY_RUN" = "true" ]; then
            echo "🔍 **This was a dry run - no actual changes were made**"
        else
            echo "✅ **Actions completed successfully**"
        fi
    } >> "$GITHUB_STEP_SUMMARY"
else
    echo ""
    echo "ℹ️  GITHUB_STEP_SUMMARY not available - summary not written to file"
fi
