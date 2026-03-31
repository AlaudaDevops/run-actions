---
name: gh-cli
description: GitHub CLI (gh) reference for AI-driven PR code review. Covers creating inline review comments, managing review threads, fetching PR diffs and details, and the complete review workflow using gh api. Load this skill before performing any PR code review.
---

# GitHub CLI for PR Code Review

This skill provides the essential `gh` CLI commands and GitHub API patterns needed to perform automated pull request code reviews. It covers creating inline comments on specific lines, managing existing review threads, and posting review summaries.

## Authentication & Identity

```bash
# Verify authentication
gh auth status

# Get your username (needed to identify your own comments later)
REVIEWER=$(gh api user --jq '.login')
echo "Reviewing as: $REVIEWER"
```

## Fetching PR Information

### PR Details

```bash
# Get PR metadata
gh pr view $PR_NUMBER --repo $REPO \
  --json number,title,state,body,author,headRefName,baseRefName,additions,deletions,changedFiles,headRefOid
```

### PR Diff

```bash
# Full diff
gh pr diff $PR_NUMBER --repo $REPO
```

### Changed Files with Patch Info

```bash
# List changed files with metadata
gh api repos/$REPO/pulls/$PR_NUMBER/files --paginate \
  --jq '.[] | {filename, status, additions, deletions, changes}'

# Full file objects including patch content
gh api repos/$REPO/pulls/$PR_NUMBER/files --paginate
```

Each file object contains:
- `filename`: path relative to repo root
- `status`: `"added"`, `"removed"`, `"modified"`, `"renamed"`
- `patch`: unified diff content for the file (**may be absent** for binary files, very large diffs, or some renames — skip inline comments for files without a `patch` field)
- `additions`, `deletions`: line counts

## Creating Inline Review Comments

### CRITICAL: Use the Pull Request Reviews API

**DO NOT** use `gh pr comment` for inline code comments. That creates issue-level comments on the PR thread, NOT inline review comments on specific code lines.

**ALWAYS** use `gh api repos/{owner}/{repo}/pulls/{number}/reviews` to create a review with inline comments.

### Creating a Review with Inline Comments

Write a JSON payload file and submit it:

```bash
cat > /tmp/review-payload.json << 'EOF'
{
  "event": "COMMENT",
  "comments": [
    {
      "path": "src/handler.go",
      "line": 42,
      "side": "RIGHT",
      "body": "**Bug** (`bug/null-pointer`): `user` may be nil here. Add a nil check before calling methods.\n\n```suggestion\nif user != nil {\n    user.Save()\n}\n```"
    },
    {
      "path": "src/config.go",
      "line": 15,
      "side": "RIGHT",
      "body": "**Warning** (`security/secrets`): This looks like a hardcoded credential. Consider using environment variables."
    }
  ]
}
EOF

gh api repos/$REPO/pulls/$PR_NUMBER/reviews \
  --method POST \
  --input /tmp/review-payload.json
```

### Review Event Types

| Event | When to Use |
|-------|-------------|
| `COMMENT` | General feedback, no approval or rejection |
| `APPROVE` | PR looks good, no blocking issues |
| `REQUEST_CHANGES` | PR has blocking issues that must be fixed |

### Single-Line Comment Fields

| Field | Required | Description |
|-------|----------|-------------|
| `path` | Yes | File path relative to repo root |
| `line` | Yes | Line number in the **new** version of the file |
| `side` | Yes | Always `"RIGHT"` for new file lines |
| `body` | Yes | Comment body (Markdown supported) |

### Multi-Line Comments

To comment on a range of lines, use `start_line` and `start_side`:

```json
{
  "path": "src/handler.go",
  "start_line": 10,
  "line": 15,
  "start_side": "RIGHT",
  "side": "RIGHT",
  "body": "This entire block should be refactored to reduce complexity."
}
```

- `start_line`: First line of the range
- `line`: Last line of the range (the anchor line)
- Both `start_side` and `side` should be `"RIGHT"` for new code

### Code Suggestions

Use GitHub's suggestion syntax in the comment body to offer one-click applicable fixes:

````markdown
**Suggestion**: Use a constant instead of a magic number.

```suggestion
const MAX_RETRIES = 3
for i := 0; i < MAX_RETRIES; i++ {
```
````

The code inside the `suggestion` fence must be the **exact replacement** for the commented line(s). GitHub renders an "Apply suggestion" button.

### Building the Payload Programmatically

When you have many comments, build the JSON with `jq`:

```bash
# Initialize payload
echo '{"event":"COMMENT","comments":[]}' > /tmp/review-payload.json

# Helper function to add a comment
add_review_comment() {
  local path="$1" line="$2" body="$3"
  jq --arg p "$path" --argjson l "$line" --arg b "$body" \
    '.comments += [{"path":$p,"line":$l,"side":"RIGHT","body":$b}]' \
    /tmp/review-payload.json > /tmp/review-payload.tmp
  mv /tmp/review-payload.tmp /tmp/review-payload.json
}

add_review_comment "src/main.go" 42 "Potential nil dereference"
add_review_comment "src/config.go" 15 "Hardcoded credential detected"

# Submit
gh api repos/$REPO/pulls/$PR_NUMBER/reviews \
  --method POST \
  --input /tmp/review-payload.json
```

### Submitting a Review Without Inline Comments

To submit just a review body (e.g., approval or request-changes) without inline comments:

```bash
gh api repos/$REPO/pulls/$PR_NUMBER/reviews \
  --method POST \
  -f event="COMMENT" \
  -f body="Overall this looks good. Minor suggestions noted inline."
```

## Managing Existing Review Comments

### List All Review Comments on the PR

```bash
gh api repos/$REPO/pulls/$PR_NUMBER/comments --paginate
```

### List Only Your Comments

```bash
REVIEWER=$(gh api user --jq '.login')
gh api repos/$REPO/pulls/$PR_NUMBER/comments --paginate \
  --jq "[.[] | select(.user.login == \"$REVIEWER\") | {id, path, line, body: (.body | .[0:100]), in_reply_to_id, created_at}]"
```

### List Only Your Top-Level Comments (Exclude Replies)

```bash
REVIEWER=$(gh api user --jq '.login')
gh api repos/$REPO/pulls/$PR_NUMBER/comments --paginate \
  --jq "[.[] | select(.user.login == \"$REVIEWER\" and .in_reply_to_id == null) | {id, path, line, body: (.body | .[0:100])}]"
```

### Update a Comment

Note: Individual review comment operations use `/pulls/comments/{comment_id}` (without the PR number).

```bash
gh api repos/$REPO/pulls/comments/$COMMENT_ID \
  --method PATCH \
  -f body="Updated: This issue has been partially addressed but still needs the nil check."
```

### Delete a Comment

```bash
gh api repos/$REPO/pulls/comments/$COMMENT_ID \
  --method DELETE
```

### Reply to a Comment Thread

```bash
gh api repos/$REPO/pulls/$PR_NUMBER/comments/$COMMENT_ID/replies \
  --method POST \
  -f body="Thanks for fixing this! The updated implementation looks correct."
```

### Resolve / Unresolve Review Threads (GraphQL)

To resolve a review thread programmatically, you need the thread's node ID via GraphQL:

```bash
# Split owner/repo for GraphQL variables
OWNER="${REPO%%/*}"
REPO_NAME="${REPO##*/}"

# Get all review threads with their IDs and resolution status
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          comments(first: 1) {
            nodes {
              databaseId
              author { login }
              body
            }
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO_NAME" -F number=$PR_NUMBER
```

```bash
# Resolve a specific thread
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { isResolved }
  }
}' -f threadId="$THREAD_NODE_ID"
```

```bash
# Unresolve a thread (if needed)
gh api graphql -f query='
mutation($threadId: ID!) {
  unresolveReviewThread(input: {threadId: $threadId}) {
    thread { isResolved }
  }
}' -f threadId="$THREAD_NODE_ID"
```

## PR Issue Comments (Thread-Level)

For posting summary comments on the PR conversation thread (NOT inline on code):

```bash
# Create a new PR issue comment
gh pr comment $PR_NUMBER --repo $REPO --body-file pr-overview.md

# Or with inline body
gh pr comment $PR_NUMBER --repo $REPO --body "## Review Summary

Overall looks good with minor issues."
```

### Upsert Pattern (Update or Create)

Use a hidden HTML marker to find and update your existing comment:

```bash
MARKER="<!-- my-review-marker -->"
COMMENTS=$(gh api repos/$REPO/issues/$PR_NUMBER/comments --paginate 2>/dev/null || echo "[]")
COMMENT_ID=$(echo "$COMMENTS" | jq -r ".[] | select(.body | contains(\"$MARKER\")) | .id" | head -1)

if [ -n "$COMMENT_ID" ] && [ "$COMMENT_ID" != "null" ]; then
  # Update existing comment
  gh api repos/$REPO/issues/comments/$COMMENT_ID \
    --method PATCH \
    -f body="$(cat comment.md)"
else
  # Create new comment
  gh pr comment $PR_NUMBER --repo $REPO --body-file comment.md
fi
```

## Line Number Mapping

### Understanding Commentable Lines

GitHub only allows inline comments on lines that appear in the diff. The `line` field must refer to a line number in the **new** version of the file (right side of the diff).

### Rules

1. **Only comment on lines visible in the diff** - added lines (`+` prefix) or context lines (no prefix)
2. **Use NEW file line numbers** - the right side of the diff
3. **Never reference deleted lines** (`-` prefix) - they don't exist in the new code
4. **The `side` field must be `"RIGHT"`** for commenting on the new version

### Calculating Line Numbers from Diff Hunks

Each hunk header follows this format: `@@ -OLD_START,OLD_COUNT +NEW_START,NEW_COUNT @@`

```diff
@@ -10,7 +10,9 @@ func main() {
     existing code      <- line 10 (context, commentable)
     existing code      <- line 11
-    removed line       <- SKIP (deleted, not in new file)
+    new line           <- line 12 (added, commentable)
+    another new line   <- line 13 (added, commentable)
     existing code      <- line 14 (context, commentable)
```

**Count only `+` lines and context lines (no prefix), starting from `NEW_START`.**

### Extracting Valid Line Numbers for a File

```bash
# Get all commentable line numbers for a specific file
gh api repos/$REPO/pulls/$PR_NUMBER/files --paginate \
  --jq '.[] | select(.filename == "src/main.go") | .patch' \
  | awk '
    /^@@/ {
      match($0, /\+([0-9]+)/, arr)
      line = arr[1]
      next
    }
    /^-/ { next }
    {
      print line
      line++
    }
  '
```

### Validating Before Commenting

Before submitting comments, verify each target line exists in the diff:

```bash
# Get valid lines as a set, then check your comment targets
VALID_LINES=$(gh api repos/$REPO/pulls/$PR_NUMBER/files --paginate \
  --jq '.[] | select(.filename == "TARGET_FILE") | .patch' \
  | awk '/^@@/{match($0,/\+([0-9]+)/,a);l=a[1];next}/^-/{next}{print l;l++}')

# Check if line 42 is valid
echo "$VALID_LINES" | grep -qx "42" && echo "Line 42 is valid" || echo "Line 42 is NOT in the diff"
```

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| Using `gh pr comment` for inline comments | Use `gh api .../pulls/.../reviews --method POST` |
| Commenting on deleted lines (`-`) | Only comment on `+` or context lines |
| Using OLD file line numbers | Always use NEW file line numbers |
| Not setting `side: "RIGHT"` | Always include `"side": "RIGHT"` |
| Posting comments one at a time | Batch all in a single review submission |
| Not cleaning up old comments | Delete obsolete comments from previous reviews |
| Using deprecated `position` parameter | Use `line` + `side` (position is legacy) |
| Guessing line numbers | Calculate from diff hunk headers or validate first |

## Complete Code Review Workflow

Follow these steps for a thorough, well-managed PR code review:

### Step 1: Identify Yourself
```bash
REVIEWER=$(gh api user --jq '.login')
```

### Step 2: Get PR Details
```bash
PR_INFO=$(gh pr view $PR_NUMBER --repo $REPO \
  --json title,body,author,headRefName,baseRefName,changedFiles,additions,deletions)
echo "$PR_INFO" | jq .
```

### Step 3: Get the Full Diff
```bash
gh pr diff $PR_NUMBER --repo $REPO
```

### Step 4: Get Changed Files with Patches
```bash
gh api repos/$REPO/pulls/$PR_NUMBER/files --paginate
```

### Step 5: Find Your Existing Review Comments
```bash
MY_COMMENTS=$(gh api repos/$REPO/pulls/$PR_NUMBER/comments --paginate \
  --jq "[.[] | select(.user.login == \"$REVIEWER\") | {id, path, line, body: (.body | .[0:100]), in_reply_to_id}]")
echo "$MY_COMMENTS"
```

### Step 6: Analyze Code
Review the diff against the codebase. Identify issues by severity:
- **Critical**: Security vulnerabilities, bugs, breaking changes
- **Warning**: Code quality issues, missing error handling
- **Suggestion**: Style improvements, refactoring opportunities

### Step 7: Clean Up Obsolete Comments
Delete your previous comments that are no longer relevant (code was fixed, lines no longer exist):
```bash
# For each obsolete comment (note: individual comment operations omit the PR number)
gh api repos/$REPO/pulls/comments/$OLD_COMMENT_ID --method DELETE
```

### Step 8: Submit Review with New Inline Comments
```bash
# Build payload with all comments
cat > /tmp/review-payload.json << 'EOF'
{
  "event": "COMMENT",
  "comments": [
    ... your comments here ...
  ]
}
EOF

gh api repos/$REPO/pulls/$PR_NUMBER/reviews \
  --method POST \
  --input /tmp/review-payload.json
```

### Step 9: Generate Output Files
Write these files in the repository root:
- **`pr-overview.md`** - Markdown summary of the review
- **`issue_count`** - Single integer: count of critical issues only
- **`status`** - `0` if PR is good to merge, `1` if it should be blocked

## Tips

- **Batch comments**: Submit all inline comments in a single review to reduce notification spam
- **Idempotent reviews**: Clean up your old comments before posting new ones to avoid duplicates
- **Validate lines**: Always verify target lines exist in the diff before commenting
- **Use `--paginate`**: Always paginate list endpoints to get complete results
- **Use `--jq`**: Filter API responses inline to reduce data processing
- **Error handling**: Check `gh api` exit codes and handle failures gracefully
- **Rate limits**: GitHub API has rate limits; batch operations where possible
- **Markdown in comments**: Use proper formatting, code blocks, and suggestion fences for clarity
