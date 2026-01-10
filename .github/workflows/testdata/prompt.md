# Pull Request Review Task

## PR Information
- **Repository**: AlaudaDevops/toolbox
- **PR Number**: #142
- **Title**: feat/adding pr dispatch support
- **Author**: @danielfbm
- **Branch**: feat/adding-pr-dispatch-support → main
- **Changes**: +858/-16 in 12 files
- **Review Style**: strict

## Shared Review Guidelines

# Code Review Skill

You are a senior software engineer performing a thorough code review on a pull request. Your goal is to provide constructive, actionable feedback that helps improve code quality.

## Instructions

When reviewing a PR, you must:
1. Analyze all changed files in the diff
2. Generate TWO output files:
   - `pr-overview.md` - A summary comment for the PR
   - `pr-comments.json` - Inline review comments in reviewdog format

## Review Guidelines

### Code Quality
- Check for clean, readable, and maintainable code
- Identify code duplication and suggest DRY improvements
- Evaluate naming conventions for clarity
- Look for proper error handling and edge cases

### Security
- Identify potential security vulnerabilities (injection, XSS, CSRF, etc.)
- Check for hardcoded secrets or credentials
- Verify proper input validation and sanitization
- Review authentication and authorization logic

### Performance
- Identify potential performance bottlenecks
- Check for unnecessary computations or database calls
- Look for memory leaks or resource management issues
- Evaluate algorithm complexity where relevant

### Best Practices
- Verify adherence to language/framework conventions
- Check for proper logging and debugging capabilities
- Evaluate test coverage for new/changed code
- Look for proper documentation where needed

### Architecture
- Assess if changes follow existing patterns in the codebase
- Check for proper separation of concerns
- Evaluate impact on other parts of the system

## Output Format 1: pr-overview.md

Write a markdown file with the following structure:

```markdown
## Summary

A brief overview of the PR changes and overall assessment (2-3 sentences).

## Review Statistics

| Category | Count |
|----------|-------|
| Critical Issues | X |
| Warnings | X |
| Suggestions | X |
| Files Reviewed | X |

## Critical Issues

> Issues that MUST be addressed before merging (security, bugs, breaking changes)

- **[filename:line]** Description of the critical issue

## Warnings

> Issues that SHOULD be addressed but are not blocking

- **[filename:line]** Description of the warning

## Suggestions

> Recommendations for improvement (nice to have)

- **[filename:line]** Description of the suggestion

## Positive Feedback

Highlight well-written code or good practices observed in this PR.

---

```

## Output Format 2: pr-comments.json

Write a JSON file with an array of review comments in reviewdog rdjson format:

```json
{
  "source": {
    "name": "ai-code-review",
    "url": "https://github.com/alaudadevops/run-actions"
  },
  "diagnostics": [
    {
      "message": "Clear description of the issue or suggestion",
      "location": {
        "path": "relative/path/to/file.ts",
        "range": {
          "start": {
            "line": 10,
            "column": 1
          },
          "end": {
            "line": 10,
            "column": 80
          }
        }
      },
      "severity": "ERROR",
      "code": {
        "value": "security/sql-injection",
        "url": "https://owasp.org/..."
      },
      "suggestions": [
        {
          "text": "Suggested replacement code\ncan be multiline"
        }
      ]
    }
  ]
}
```

### Severity Levels

Use these severity levels appropriately:
- `ERROR` - Critical issues that must be fixed (security vulnerabilities, bugs, breaking changes)
- `WARNING` - Issues that should be fixed but are not blocking
- `INFO` - Suggestions for improvement
- `HINT` - Minor style or convention suggestions

### Code Categories

Use descriptive code values to categorize issues:
- `security/*` - Security issues (e.g., `security/xss`, `security/sql-injection`, `security/secrets`)
- `bug/*` - Potential bugs (e.g., `bug/null-pointer`, `bug/race-condition`, `bug/off-by-one`)
- `performance/*` - Performance issues (e.g., `performance/n-plus-one`, `performance/memory-leak`)
- `style/*` - Style issues (e.g., `style/naming`, `style/formatting`)
- `refactor/*` - Refactoring suggestions (e.g., `refactor/duplication`, `refactor/complexity`)
- `docs/*` - Documentation issues (e.g., `docs/missing`, `docs/outdated`)
- `test/*` - Testing issues (e.g., `test/missing`, `test/coverage`)

### Suggestions Field

When providing a `suggestions` array:
- Include concrete code fixes when possible
- The `text` field should contain the exact replacement code
- For multi-line suggestions, use `\n` for newlines

## Important Notes

- Be constructive and respectful in your feedback
- Focus on the most impactful issues first
- Provide specific line references for all issues
- Include code examples for suggested fixes when helpful
- Consider the context and constraints of the project
- Group related issues when they affect multiple locations
- Avoid nitpicking on minor style issues unless they violate project conventions
- If no issues are found, still provide positive feedback in the overview

## Example Workflow

1. Read the PR diff provided
2. Analyze each changed file for issues
3. Write `pr-overview.md` with the summary and categorized issues
4. Write `pr-comments.json` with detailed inline comments
5. Ensure all file paths in comments are relative to the repository root
6. Ensure line numbers match the actual diff (use the "new" line numbers, not old)

## Handling Large PRs

For large PRs (>500 lines changed):
- Focus on the most critical issues first
- Group similar issues together
- Limit to the top 20 most important comments
- Mention in the overview that the review focused on high-priority items


## Your Task

1. Review the PR diff below thoroughly
2. Identify issues based on the guidelines above
3. Provide your review in the specified format

## PR Diff

```diff
diff --git a/.github/workflows/trigger-review.yaml b/.github/workflows/trigger-review.yaml
new file mode 100644
index 0000000..f3fad51
--- /dev/null
+++ b/.github/workflows/trigger-review.yaml
@@ -0,0 +1,47 @@
+# Example workflow for triggering Kilo PR Review from your repository
+# Copy this file to .github/workflows/kilo-review.yaml in your repository
+
+name: PR Review
+
+on:
+  pull_request:
+    types: [opened, synchronize, reopened]
+
+  # Allow manual trigger for existing PRs
+  workflow_dispatch:
+    inputs:
+      pr_number:
+        description: "PR number to review (leave empty for latest)"
+        required: false
+        type: string
+
+jobs:
+  trigger-review:
+    runs-on: ubuntu-latest
+    # Skip review for draft PRs and bot PRs
+    if: github.event.pull_request.draft != true && github.actor != 'dependabot[bot]'
+
+    steps:
+      - name: Determine PR number
+        id: pr-number
+        run: |
+          if [ -n "${{ inputs.pr_number }}" ]; then
+            echo "pr_number=${{ inputs.pr_number }}" >> $GITHUB_OUTPUT
+          elif [ -n "${{ github.event.pull_request.number }}" ]; then
+            echo "pr_number=${{ github.event.pull_request.number }}" >> $GITHUB_OUTPUT
+          else
+            echo "❌ No PR number provided"
+            exit 1
+          fi
+
+      - name: Trigger Kilo PR Review
+        run: |
+          # Trigger the kilo-pr-review workflow in run-actions repository
+          gh workflow run kilo-pr-review.yaml \
+            --repo alaudadevops/run-actions \
+            --field repository="${{ github.repository }}" \
+            --field pr_number="${{ steps.pr-number.outputs.pr_number }}"
+
+          echo "✅ Kilo PR Review triggered for ${{ github.repository }}#${{ steps.pr-number.outputs.pr_number }}"
+        env:
+          GH_TOKEN: ${{ secrets.TOKEN }}
diff --git a/pr-cli/README.md b/pr-cli/README.md
index dd63937..d548a48 100644
--- a/pr-cli/README.md
+++ b/pr-cli/README.md
@@ -14,6 +14,8 @@ PR CLI is a tool that processes comment commands on pull requests and executes c
 - **Multiple merge methods**: merge, squash, rebase
 - **Reviewer management**: Assign and unassign reviewers
 - **Status checks**: Verify CI/CD status before operations
+- **Webhook Server**: Run as a service to receive GitHub/GitLab webhooks directly
+- **PR Event Handling**: Trigger GitHub Actions workflows on PR open/update events
 
 ## Installation
 
@@ -40,6 +42,8 @@ go install github.com/AlaudaDevops/toolbox/pr-cli@latest
 | **This README** | Project overview, installation, and quick start | New users getting started |
 | **[📋 CLI Reference](docs/usage.md)** | Complete command-line usage guide | Users needing detailed CLI documentation |
 | **[🔧 Pipeline Integration](pipeline/README.md)** | Tekton Pipeline setup and configuration | DevOps teams setting up automation |
+| **[🌐 Webhook Service](docs/webhook-usage.md)** | Webhook server deployment and configuration | Teams running PR CLI as a service |
+| **[⚡ Webhook Quick Start](docs/webhook-quick-start.md)** | Quick setup guide for webhook service | Users setting up webhook service quickly |
 
 ## Quick Start
 
@@ -173,6 +177,41 @@ pr-cli --platform github \
 
 > 📘 **Pipeline Integration**: For Tekton Pipeline integration and detailed command usage, see [pipeline/README.md](pipeline/README.md)
 
+## Webhook Service Mode
+
+PR CLI can run as a standalone webhook server that receives events directly from GitHub/GitLab:
+
+```bash
+# Start webhook server
+pr-cli serve \
+  --webhook-secret="your-secret" \
+  --allowed-repos="myorg/*" \
+  --token="$GITHUB_TOKEN"
+```
+
+### PR Event Handling
+
+The webhook service can also trigger GitHub Actions workflows when PRs are opened or updated:
+
+```bash
+# Enable PR event handling to trigger workflows
+pr-cli serve \
+  --pr-event-enabled \
+  --workflow-file=.github/workflows/pr-check.yml \
+  --webhook-secret="your-secret" \
+  --allowed-repos="myorg/*"
+```
+
+When a PR is opened or updated, the service triggers the specified workflow with inputs like `pr_number`, `pr_action`, `head_ref`, `head_sha`, `base_ref`, and `sender`.
+
+> ⚠️ **Security Considerations**: When enabling PR event handling with workflow dispatch, ensure:
+> - The `--allowed-repos` flag is configured to restrict which repositories can trigger workflows
+> - The workflow file being triggered has appropriate security controls and doesn't execute untrusted code
+> - The GitHub token used has minimal required permissions (only `actions:write` for dispatch)
+> - Webhook signature validation is enabled (`--require-signature=true`, the default)
+
+> 📘 **Full Documentation**: See [Webhook Service Guide](docs/webhook-usage.md) for complete configuration options and deployment instructions.
+
 ## Configuration
 
 ### Command Line Flags
diff --git a/pr-cli/cmd/serve.go b/pr-cli/cmd/serve.go
index 612ce60..2da99cb 100644
--- a/pr-cli/cmd/serve.go
+++ b/pr-cli/cmd/serve.go
@@ -38,7 +38,8 @@ PR comment commands. This mode eliminates the need for Tekton Pipelines and prov
 faster response times with lower resource usage.
 
 The server listens for webhook events, validates signatures, and executes PR commands
-using the same logic as the CLI mode.
+using the same logic as the CLI mode. It can also handle pull_request events to trigger
+GitHub Actions workflows via workflow_dispatch.
 
 Example:
   # Start server with default settings
@@ -50,6 +51,9 @@ Example:
   # Start with TLS
   pr-cli serve --tls-enabled --tls-cert-file=/etc/certs/tls.crt --tls-key-file=/etc/certs/tls.key
 
+  # Start with PR event handling to trigger workflows
+  pr-cli serve --pr-event-enabled --workflow-file=.github/workflows/pr-check.yml
+
 Environment Variables:
   LISTEN_ADDR              Server listen address (default: :8080)
   WEBHOOK_PATH             Webhook endpoint path (default: /webhook)
@@ -65,6 +69,11 @@ Environment Variables:
   QUEUE_SIZE               Job queue size (default: 100)
   RATE_LIMIT_ENABLED       Enable rate limiting (default: true)
   RATE_LIMIT_REQUESTS      Max requests per minute per IP (default: 100)
+  PR_EVENT_ENABLED         Enable pull_request event handling (default: false)
+  PR_EVENT_ACTIONS         Comma-separated PR actions to listen for (default: opened,synchronize,reopened,ready_for_review,edited)
+  WORKFLOW_FILE            Workflow file to trigger for PR events
+  WORKFLOW_REF             Git ref for workflow dispatch (default: main)
+  WORKFLOW_INPUTS          Static workflow inputs (key=value,key=value format)
 
   Plus all PR CLI environment variables (PR_TOKEN, PR_PLATFORM, etc.)
 `,
@@ -100,6 +109,15 @@ func init() {
 	serveCmd.Flags().Bool("rate-limit-enabled", true, "Enable rate limiting")
 	serveCmd.Flags().Int("rate-limit-requests", 100, "Max requests per minute per IP")
 
+	// Pull request event flags
+	serveCmd.Flags().Bool("pr-event-enabled", false, "Enable pull_request event handling to trigger workflows")
+	serveCmd.Flags().StringSlice("pr-event-actions", []string{"opened", "synchronize", "reopened", "ready_for_review", "edited"}, "PR actions to listen for")
+
+	// Workflow dispatch flags
+	serveCmd.Flags().String("workflow-file", "", "Workflow file to trigger (e.g., .github/workflows/pr-check.yml)")
+	serveCmd.Flags().String("workflow-ref", "main", "Git ref to use for workflow dispatch")
+	serveCmd.Flags().StringToString("workflow-inputs", nil, "Static workflow inputs (key=value)")
+
 	// Add PR CLI flags to serve command
 	prOption.AddFlags(serveCmd.Flags())
 }
@@ -167,6 +185,25 @@ func runServe(cmd *cobra.Command, args []string) error {
 		webhookConfig.RateLimitRequests = rateLimitReqs
 	}
 
+	// Pull request event configuration
+	if prEventEnabled, _ := cmd.Flags().GetBool("pr-event-enabled"); cmd.Flags().Changed("pr-event-enabled") {
+		webhookConfig.PREventEnabled = prEventEnabled
+	}
+	if prEventActions, _ := cmd.Flags().GetStringSlice("pr-event-actions"); cmd.Flags().Changed("pr-event-actions") {
+		webhookConfig.PREventActions = prEventActions
+	}
+
+	// Workflow dispatch configuration
+	if workflowFile, _ := cmd.Flags().GetString("workflow-file"); workflowFile != "" {
+		webhookConfig.WorkflowFile = workflowFile
+	}
+	if workflowRef, _ := cmd.Flags().GetString("workflow-ref"); cmd.Flags().Changed("workflow-ref") {
+		webhookConfig.WorkflowRef = workflowRef
+	}
+	if workflowInputs, _ := cmd.Flags().GetStringToString("workflow-inputs"); len(workflowInputs) > 0 {
+		webhookConfig.WorkflowInputs = workflowInputs
+	}
+
 	// Load from environment variables (overrides flags)
 	if err := webhookConfig.LoadFromEnv(); err != nil {
 		return fmt.Errorf("failed to load webhook config from environment: %w", err)
diff --git a/pr-cli/deploy/base/configmap.yaml b/pr-cli/deploy/base/configmap.yaml
index 7c4dd17..fb34478 100644
--- a/pr-cli/deploy/base/configmap.yaml
+++ b/pr-cli/deploy/base/configmap.yaml
@@ -8,19 +8,27 @@ data:
   WEBHOOK_PATH: "/webhook"
   HEALTH_PATH: "/health"
   METRICS_PATH: "/metrics"
-  
+
   # Processing Configuration
   ASYNC_PROCESSING: "true"
   WORKER_COUNT: "10"
   QUEUE_SIZE: "100"
-  
+
   # Rate Limiting
   RATE_LIMIT_ENABLED: "true"
   RATE_LIMIT_REQUESTS: "100"
-  
+
   # Security
   REQUIRE_SIGNATURE: "true"
-  
+
+  # Pull Request Event Handling
+  # Set PR_EVENT_ENABLED to "true" to trigger workflows on PR events
+  PR_EVENT_ENABLED: "false"
+  PR_EVENT_ACTIONS: "opened,synchronize,reopened,ready_for_review,edited"
+  # WORKFLOW_FILE: ".github/workflows/pr-check.yml"  # Required if PR_EVENT_ENABLED is true
+  WORKFLOW_REF: "main"
+  # WORKFLOW_INPUTS: "key1=value1,key2=value2"  # Optional static inputs
+
   # PR CLI Configuration
   PR_PLATFORM: "github"
   PR_LGTM_THRESHOLD: "1"
diff --git a/pr-cli/docs/webhook-quick-start.md b/pr-cli/docs/webhook-quick-start.md
index 6235af7..20b8772 100644
--- a/pr-cli/docs/webhook-quick-start.md
+++ b/pr-cli/docs/webhook-quick-start.md
@@ -142,6 +142,11 @@ kubectl logs -f deployment/pr-cli-webhook -n pr-automation
 | `QUEUE_SIZE` | Job queue size | `100` | No |
 | `RATE_LIMIT_ENABLED` | Enable rate limiting | `true` | No |
 | `RATE_LIMIT_REQUESTS` | Max requests per minute per IP | `100` | No |
+| `PR_EVENT_ENABLED` | Enable pull_request event handling | `false` | No |
+| `PR_EVENT_ACTIONS` | PR actions to listen for | `opened,synchronize,reopened,ready_for_review,edited` | No |
+| `WORKFLOW_FILE` | Workflow file to trigger | - | If PR_EVENT_ENABLED |
+| `WORKFLOW_REF` | Git ref for workflow dispatch | `main` | No |
+| `WORKFLOW_INPUTS` | Static workflow inputs (key=value,key=value) | - | No |
 
 ### Command-Line Flags
 
@@ -165,6 +170,11 @@ Flags:
   --queue-size int              Job queue size (default 100)
   --rate-limit-enabled          Enable rate limiting (default true)
   --rate-limit-requests int     Max requests per minute per IP (default 100)
+  --pr-event-enabled            Enable pull_request event handling (default false)
+  --pr-event-actions strings    PR actions to listen for (default [opened,synchronize,reopened,ready_for_review,edited])
+  --workflow-file string        Workflow file to trigger (e.g., .github/workflows/pr-check.yml)
+  --workflow-ref string         Git ref for workflow dispatch (default "main")
+  --workflow-inputs strings     Static workflow inputs (key=value format)
 ```
 
 ## Monitoring
@@ -192,8 +202,12 @@ curl http://localhost:8080/metrics
 
 # Prometheus metrics:
 # pr_cli_webhook_requests_total{platform="github",event_type="issue_comment",status="success"} 150
+# pr_cli_webhook_requests_total{platform="github",event_type="pull_request",status="success"} 75
 # pr_cli_webhook_processing_duration_seconds{platform="github",command="lgtm"} 0.234
 # pr_cli_command_execution_total{platform="github",command="merge",status="success"} 45
+# pr_cli_pr_event_total{platform="github",action="opened",status="success"} 30
+# pr_cli_pr_event_total{platform="github",action="synchronize",status="success"} 45
+# pr_cli_workflow_dispatch_total{platform="github",workflow=".github/workflows/pr-check.yml",status="success"} 75
 # pr_cli_queue_size 5
 # pr_cli_active_workers 10
 ```
diff --git a/pr-cli/docs/webhook-usage.md b/pr-cli/docs/webhook-usage.md
index a185fa4..16f80b1 100644
--- a/pr-cli/docs/webhook-usage.md
+++ b/pr-cli/docs/webhook-usage.md
@@ -22,7 +22,8 @@ export WEBHOOK_SECRET="your-webhook-secret"
 3. Set Content type to: `application/json`
 4. Set Secret to: `your-webhook-secret` (same as WEBHOOK_SECRET)
 5. Select "Let me select individual events" and choose:
-   - Issue comments
+   - Issue comments (for PR comment commands like `/lgtm`, `/merge`)
+   - Pull requests (if using PR event handling to trigger workflows)
 6. Save the webhook
 
 ### 3. Test the Webhook
@@ -59,6 +60,13 @@ Create a comment on a pull request with a command like `/lgtm` and the server wi
 - `RATE_LIMIT_ENABLED` - Enable rate limiting (default: `true`)
 - `RATE_LIMIT_REQUESTS` - Max requests per minute per IP (default: `100`)
 
+#### Pull Request Event Handling
+- `PR_EVENT_ENABLED` - Enable pull_request event handling to trigger workflows (default: `false`)
+- `PR_EVENT_ACTIONS` - Comma-separated PR actions to listen for (default: `opened,synchronize,reopened,ready_for_review,edited`)
+- `WORKFLOW_FILE` - Workflow file to trigger for PR events (e.g., `.github/workflows/pr-check.yml`)
+- `WORKFLOW_REF` - Git ref to use for workflow dispatch (default: `main`)
+- `WORKFLOW_INPUTS` - Static workflow inputs in `key=value,key=value` format
+
 #### PR CLI Configuration
 All standard PR CLI environment variables are supported:
 - `PR_TOKEN` - GitHub/GitLab API token (required)
@@ -118,11 +126,13 @@ All environment variables can also be set via command-line flags:
 
 The webhook service exposes the following Prometheus metrics:
 
-- `webhook_requests_total` - Total webhook requests (labels: platform, event_type, status)
-- `webhook_processing_duration_seconds` - Webhook processing duration (labels: platform, command)
-- `command_execution_total` - Total command executions (labels: platform, command, status)
-- `webhook_queue_size` - Current job queue size
-- `webhook_active_workers` - Number of active workers
+- `pr_cli_webhook_requests_total` - Total webhook requests (labels: platform, event_type, status)
+- `pr_cli_webhook_processing_duration_seconds` - Webhook processing duration (labels: platform, command)
+- `pr_cli_command_execution_total` - Total command executions (labels: platform, command, status)
+- `pr_cli_queue_size` - Current job queue size
+- `pr_cli_active_workers` - Number of active workers
+- `pr_cli_pr_event_total` - Total pull_request events processed (labels: platform, action, status)
+- `pr_cli_workflow_dispatch_total` - Total workflow dispatch triggers (labels: platform, workflow, status)
 
 ## Security
 
@@ -301,6 +311,74 @@ export ALLOWED_REPOS="myorg/*"
   --queue-size=200
 ```
 
+### PR Event Handling (Trigger Workflows)
+
+Enable the webhook to trigger GitHub Actions workflows when PRs are opened or updated:
+
+```bash
+export PR_TOKEN="ghp_xxxxxxxxxxxx"
+export WEBHOOK_SECRET="my-secret-key"
+export ALLOWED_REPOS="myorg/*"
+export PR_EVENT_ENABLED="true"
+export WORKFLOW_FILE=".github/workflows/pr-check.yml"
+export WORKFLOW_REF="main"
+./pr-cli serve --verbose
+```
+
+Or with CLI flags:
+
+```bash
+./pr-cli serve \
+  --pr-event-enabled \
+  --workflow-file=.github/workflows/pr-check.yml \
+  --workflow-ref=main \
+  --pr-event-actions=opened,synchronize,reopened \
+  --allowed-repos="myorg/*"
+```
+
+The triggered workflow will receive these inputs:
+- `pr_number` - Pull request number
+- `pr_action` - The action (opened, synchronize, etc.)
+- `head_ref` - Source branch name
+- `head_sha` - Head commit SHA
+- `base_ref` - Target branch name
+- `sender` - User who triggered the event
+
+Example workflow that can be triggered:
+
+```yaml
+# .github/workflows/pr-check.yml
+name: PR Check
+on:
+  workflow_dispatch:
+    inputs:
+      pr_number:
+        description: 'Pull request number'
+        required: true
+      pr_action:
+        description: 'PR action'
+        required: true
+      head_ref:
+        description: 'Head branch'
+        required: true
+      head_sha:
+        description: 'Head SHA'
+        required: true
+
+jobs:
+  check:
+    runs-on: ubuntu-latest
+    steps:
+      - uses: actions/checkout@v4
+        with:
+          ref: ${{ inputs.head_sha }}
+      - name: Run checks
+        run: |
+          echo "Checking PR #${{ inputs.pr_number }}"
+          echo "Action: ${{ inputs.pr_action }}"
+          # Add your checks here
+```
+
 ### GitLab Setup
 
 ```bash
diff --git a/pr-cli/pkg/config/webhook.go b/pr-cli/pkg/config/webhook.go
index 06de9a3..a1104d2 100644
--- a/pr-cli/pkg/config/webhook.go
+++ b/pr-cli/pkg/config/webhook.go
@@ -50,6 +50,15 @@ type WebhookConfig struct {
 	RateLimitEnabled  bool `json:"rate_limit_enabled" yaml:"rate_limit_enabled" mapstructure:"rate-limit-enabled"`
 	RateLimitRequests int  `json:"rate_limit_requests" yaml:"rate_limit_requests" mapstructure:"rate-limit-requests"`
 
+	// Pull Request event configuration
+	PREventEnabled bool     `json:"pr_event_enabled" yaml:"pr_event_enabled" mapstructure:"pr-event-enabled"`
+	PREventActions []string `json:"pr_event_actions" yaml:"pr_event_actions" mapstructure:"pr-event-actions"`
+
+	// Workflow dispatch configuration
+	WorkflowFile   string            `json:"workflow_file" yaml:"workflow_file" mapstructure:"workflow-file"`
+	WorkflowRef    string            `json:"workflow_ref" yaml:"workflow_ref" mapstructure:"workflow-ref"`
+	WorkflowInputs map[string]string `json:"workflow_inputs" yaml:"workflow_inputs" mapstructure:"workflow-inputs"`
+
 	// Base PR CLI configuration
 	BaseConfig *Config `json:"-" yaml:"-"`
 }
@@ -68,6 +77,9 @@ func NewDefaultWebhookConfig() *WebhookConfig {
 		QueueSize:         100,
 		RateLimitEnabled:  true,
 		RateLimitRequests: 100,
+		PREventEnabled:    false,
+		PREventActions:    []string{"opened", "synchronize", "reopened", "ready_for_review", "edited"},
+		WorkflowRef:       "main",
 		BaseConfig:        NewDefaultConfig(),
 	}
 }
@@ -146,6 +158,36 @@ func (wc *WebhookConfig) LoadFromEnv() error {
 		}
 	}
 
+	// Pull Request event configuration
+	if prEventEnabled := os.Getenv("PR_EVENT_ENABLED"); prEventEnabled != "" {
+		wc.PREventEnabled = prEventEnabled == "true"
+	}
+	if prEventActions := os.Getenv("PR_EVENT_ACTIONS"); prEventActions != "" {
+		wc.PREventActions = strings.Split(prEventActions, ",")
+		for i := range wc.PREventActions {
+			wc.PREventActions[i] = strings.TrimSpace(wc.PREventActions[i])
+		}
+	}
+
+	// Workflow dispatch configuration
+	if workflowFile := os.Getenv("WORKFLOW_FILE"); workflowFile != "" {
+		wc.WorkflowFile = workflowFile
+	}
+	if workflowRef := os.Getenv("WORKFLOW_REF"); workflowRef != "" {
+		wc.WorkflowRef = workflowRef
+	}
+	if workflowInputs := os.Getenv("WORKFLOW_INPUTS"); workflowInputs != "" {
+		// Parse as key=value,key=value format
+		wc.WorkflowInputs = make(map[string]string)
+		pairs := strings.Split(workflowInputs, ",")
+		for _, pair := range pairs {
+			kv := strings.SplitN(strings.TrimSpace(pair), "=", 2)
+			if len(kv) == 2 {
+				wc.WorkflowInputs[strings.TrimSpace(kv[0])] = strings.TrimSpace(kv[1])
+			}
+		}
+	}
+
 	return nil
 }
 
@@ -174,12 +216,32 @@ func (wc *WebhookConfig) Validate() error {
 	if wc.RateLimitEnabled && wc.RateLimitRequests < 1 {
 		return fmt.Errorf("rate limit requests must be at least 1")
 	}
+	if wc.PREventEnabled {
+		trimmedWorkflowFile := strings.TrimSpace(wc.WorkflowFile)
+		if trimmedWorkflowFile == "" {
+			return fmt.Errorf("workflow file is required when PR event handling is enabled")
+		}
+		if !isValidWorkflowPath(trimmedWorkflowFile) {
+			return fmt.Errorf("workflow file path %q is invalid: must be a valid file path (e.g., .github/workflows/pr-check.yml)", wc.WorkflowFile)
+		}
+		wc.WorkflowFile = trimmedWorkflowFile
+	}
 	if wc.BaseConfig == nil {
 		return fmt.Errorf("base config is required")
 	}
 	return nil
 }
 
+func isValidWorkflowPath(path string) bool {
+	if path == "" {
+		return false
+	}
+	if strings.Contains(path, "..") {
+		return false
+	}
+	return strings.HasSuffix(path, ".yml") || strings.HasSuffix(path, ".yaml")
+}
+
 // DebugString returns a string representation with sensitive data redacted
 func (wc *WebhookConfig) DebugString() string {
 	return fmt.Sprintf("WebhookConfig{ListenAddr: %s, WebhookPath: %s, RequireSignature: %v, AsyncProcessing: %v, WorkerCount: %d, QueueSize: %d}",
diff --git a/pr-cli/pkg/platforms/github/client.go b/pr-cli/pkg/platforms/github/client.go
index 6d9a950..6cf93bd 100644
--- a/pr-cli/pkg/platforms/github/client.go
+++ b/pr-cli/pkg/platforms/github/client.go
@@ -1688,3 +1688,23 @@ func (c *Client) RerunWorkflowRunFailedJobs(runID int64) error {
 	c.Infof("Successfully triggered rerun of failed jobs for workflow run ID: %d", runID)
 	return nil
 }
+
+// TriggerWorkflowDispatch triggers a workflow via workflow_dispatch event
+func (c *Client) TriggerWorkflowDispatch(workflowFile, ref string, inputs map[string]interface{}) error {
+	c.Debugf("Triggering workflow dispatch: workflow=%s, ref=%s", workflowFile, ref)
+
+	event := github.CreateWorkflowDispatchEventRequest{
+		Ref:    ref,
+		Inputs: inputs,
+	}
+
+	_, err := c.client.Actions.CreateWorkflowDispatchEventByFileName(
+		c.ctx, c.owner, c.repo, workflowFile, event,
+	)
+	if err != nil {
+		return fmt.Errorf("failed to trigger workflow dispatch for %s: %w", workflowFile, err)
+	}
+
+	c.Infof("Successfully triggered workflow: %s on ref: %s", workflowFile, ref)
+	return nil
+}
diff --git a/pr-cli/pkg/webhook/handlers.go b/pr-cli/pkg/webhook/handlers.go
index 8f97f3a..958914f 100644
--- a/pr-cli/pkg/webhook/handlers.go
+++ b/pr-cli/pkg/webhook/handlers.go
@@ -24,8 +24,10 @@ import (
 	"time"
 
 	"github.com/AlaudaDevops/toolbox/pr-cli/internal/version"
-	"github.com/sirupsen/logrus"
+	"github.com/AlaudaDevops/toolbox/pr-cli/pkg/git"
+	"github.com/AlaudaDevops/toolbox/pr-cli/pkg/platforms/github"
 	"github.com/google/uuid"
+	"github.com/sirupsen/logrus"
 )
 
 // handleWebhook processes incoming webhook requests
@@ -38,7 +40,6 @@ func (s *Server) handleWebhook(w http.ResponseWriter, r *http.Request) {
 		return
 	}
 
-
 	// Read request body
 	body, err := io.ReadAll(r.Body)
 	if err != nil {
@@ -72,8 +73,8 @@ func (s *Server) handleWebhook(w http.ResponseWriter, r *http.Request) {
 		s.logger.Infof("No eventID found in webhook headers, generated a new one: %q", eventID)
 	}
 	logger := s.logger.WithFields(logrus.Fields{
-		"event_id": eventID,
-		"platform": platform,
+		"event_id":   eventID,
+		"platform":   platform,
 		"event_type": eventType,
 	})
 	s.logger.Infof("Received webhook event %q of type %q from %s", eventID, eventType, platform)
@@ -100,7 +101,13 @@ func (s *Server) handleWebhook(w http.ResponseWriter, r *http.Request) {
 		}
 	}
 
-	// Parse webhook payload
+	// Handle pull_request events separately
+	if platform == "github" && eventType == "pull_request" {
+		s.handlePullRequestEvent(w, r, body, logger, platform, eventType, startTime)
+		return
+	}
+
+	// Parse webhook payload for issue_comment events
 	var event *WebhookEvent
 	switch platform {
 	case "github":
@@ -217,3 +224,123 @@ func (s *Server) handleReadiness(w http.ResponseWriter, r *http.Request) {
 	w.WriteHeader(http.StatusOK)
 	fmt.Fprint(w, "OK")
 }
+
+// handlePullRequestEvent handles GitHub pull_request webhook events
+func (s *Server) handlePullRequestEvent(w http.ResponseWriter, r *http.Request, body []byte, logger *logrus.Entry, platform, eventType string, startTime time.Time) {
+	// Check if PR event handling is enabled
+	if !s.config.PREventEnabled {
+		logger.Debug("pull_request events disabled, skipping")
+		w.WriteHeader(http.StatusOK)
+		fmt.Fprint(w, "OK (pull_request events disabled)")
+		WebhookRequestsTotal.WithLabelValues(platform, eventType, "disabled").Inc()
+		return
+	}
+
+	// Parse pull_request webhook payload
+	prEvent, err := ParseGitHubPullRequestWebhook(body, s.config.PREventActions)
+	if err != nil {
+		logger.Debugf("PR webhook parsing skipped: %v", err)
+		w.WriteHeader(http.StatusOK)
+		fmt.Fprintf(w, "OK (skipped: %v)", err)
+		WebhookRequestsTotal.WithLabelValues(platform, eventType, "skipped").Inc()
+		return
+	}
+
+	// Validate repository
+	if err := ValidateRepository(prEvent.Repository.Owner, prEvent.Repository.Name, s.config.AllowedRepos); err != nil {
+		logger.Warnf("Repository not allowed: %v", err)
+		http.Error(w, "Repository not allowed", http.StatusForbidden)
+		WebhookRequestsTotal.WithLabelValues(platform, eventType, "forbidden").Inc()
+		return
+	}
+
+	// Log the event
+	logger = logger.WithFields(logrus.Fields{
+		"repository": fmt.Sprintf("%s/%s", prEvent.Repository.Owner, prEvent.Repository.Name),
+		"pr_number":  prEvent.PullRequest.Number,
+		"pr_action":  prEvent.Action,
+		"sender":     prEvent.Sender.Login,
+	})
+	logger.Info("Received pull_request webhook event")
+
+	// Process the PR event (trigger workflow)
+	if err := s.processPullRequestEvent(prEvent); err != nil {
+		logger.Errorf("Failed to process pull_request event: %v", err)
+		http.Error(w, "Failed to process pull_request event", http.StatusInternalServerError)
+		PREventProcessingTotal.WithLabelValues(platform, prEvent.Action, "error").Inc()
+		return
+	}
+
+	// Success response
+	w.WriteHeader(http.StatusOK)
+	fmt.Fprint(w, "OK")
+	PREventProcessingTotal.WithLabelValues(platform, prEvent.Action, "success").Inc()
+	WebhookRequestsTotal.WithLabelValues(platform, eventType, "success").Inc()
+	WebhookProcessingDuration.WithLabelValues(platform, "pull_request").Observe(time.Since(startTime).Seconds())
+}
+
+// processPullRequestEvent triggers a workflow dispatch for a pull_request event
+func (s *Server) processPullRequestEvent(event *PRWebhookEvent) error {
+	// Create GitHub client configuration
+	cfg := &git.Config{
+		Platform: event.Platform,
+		Token:    s.config.BaseConfig.Token,
+		BaseURL:  s.config.BaseConfig.BaseURL,
+		Owner:    event.Repository.Owner,
+		Repo:     event.Repository.Name,
+		PRNum:    event.PullRequest.Number,
+	}
+
+	// Create GitHub client using factory
+	factory := &github.Factory{}
+	client, err := factory.CreateClient(s.logger, cfg)
+	if err != nil {
+		return fmt.Errorf("failed to create GitHub client for repo %s/%s: %w",
+			event.Repository.Owner, event.Repository.Name, err)
+	}
+
+	// Cast to GitHub client to access TriggerWorkflowDispatch
+	ghClient, ok := client.(*github.Client)
+	if !ok {
+		return fmt.Errorf("expected GitHub client for platform %s, got different client type", event.Platform)
+	}
+
+	// Build workflow inputs from PR event
+	inputs := map[string]interface{}{
+		"pr_number": fmt.Sprintf("%d", event.PullRequest.Number),
+		"pr_action": event.Action,
+		"head_ref":  event.PullRequest.HeadRef,
+		"head_sha":  event.PullRequest.HeadSHA,
+		"base_ref":  event.PullRequest.BaseRef,
+		"sender":    event.Sender.Login,
+	}
+
+	s.logger.Debugf("Built workflow inputs from PR event: pr_number=%d, pr_action=%s, head_ref=%s, head_sha=%s, base_ref=%s, sender=%s",
+		event.PullRequest.Number, event.Action, event.PullRequest.HeadRef, event.PullRequest.HeadSHA, event.PullRequest.BaseRef, event.Sender.Login)
+
+	// Merge with configured static inputs
+	if len(s.config.WorkflowInputs) > 0 {
+		s.logger.Debugf("Merging %d static workflow inputs with dynamic PR inputs", len(s.config.WorkflowInputs))
+		for k, v := range s.config.WorkflowInputs {
+			if _, exists := inputs[k]; exists {
+				s.logger.Debugf("Static input %q overriding dynamic input", k)
+			}
+			inputs[k] = v
+		}
+	}
+
+	// Trigger workflow dispatch
+	s.logger.Infof("Triggering workflow dispatch: workflow=%s, ref=%s, repo=%s/%s, pr=%d",
+		s.config.WorkflowFile, s.config.WorkflowRef, event.Repository.Owner, event.Repository.Name, event.PullRequest.Number)
+
+	if err := ghClient.TriggerWorkflowDispatch(s.config.WorkflowFile, s.config.WorkflowRef, inputs); err != nil {
+		WorkflowDispatchTotal.WithLabelValues(event.Platform, s.config.WorkflowFile, "error").Inc()
+		return fmt.Errorf("failed to trigger workflow dispatch for workflow %q on ref %q: %w",
+			s.config.WorkflowFile, s.config.WorkflowRef, err)
+	}
+
+	WorkflowDispatchTotal.WithLabelValues(event.Platform, s.config.WorkflowFile, "success").Inc()
+	s.logger.Infof("Successfully triggered workflow %s for PR #%d (action=%s, head_sha=%s)",
+		s.config.WorkflowFile, event.PullRequest.Number, event.Action, event.PullRequest.HeadSHA)
+	return nil
+}
diff --git a/pr-cli/pkg/webhook/metrics.go b/pr-cli/pkg/webhook/metrics.go
index d437398..b115334 100644
--- a/pr-cli/pkg/webhook/metrics.go
+++ b/pr-cli/pkg/webhook/metrics.go
@@ -65,4 +65,22 @@ var (
 			Help: "Number of active worker goroutines",
 		},
 	)
+
+	// PREventProcessingTotal counts pull_request events processed
+	PREventProcessingTotal = promauto.NewCounterVec(
+		prometheus.CounterOpts{
+			Name: "pr_cli_pr_event_total",
+			Help: "Total number of pull_request events processed",
+		},
+		[]string{"platform", "action", "status"},
+	)
+
+	// WorkflowDispatchTotal counts workflow dispatch triggers
+	WorkflowDispatchTotal = promauto.NewCounterVec(
+		prometheus.CounterOpts{
+			Name: "pr_cli_workflow_dispatch_total",
+			Help: "Total number of workflow dispatch triggers",
+		},
+		[]string{"platform", "workflow", "status"},
+	)
 )
diff --git a/pr-cli/pkg/webhook/parser.go b/pr-cli/pkg/webhook/parser.go
index 1e243ad..30bff56 100644
--- a/pr-cli/pkg/webhook/parser.go
+++ b/pr-cli/pkg/webhook/parser.go
@@ -91,6 +91,60 @@ type GitHubWebhookPayload struct {
 	} `json:"sender"`
 }
 
+// GitHubPullRequestPayload represents GitHub pull_request webhook payload structure
+type GitHubPullRequestPayload struct {
+	Action      string `json:"action"`
+	Number      int    `json:"number"`
+	PullRequest struct {
+		Number int    `json:"number"`
+		State  string `json:"state"`
+		Title  string `json:"title"`
+		Draft  bool   `json:"draft"`
+		User   struct {
+			Login string `json:"login"`
+		} `json:"user"`
+		Head struct {
+			Ref string `json:"ref"`
+			SHA string `json:"sha"`
+		} `json:"head"`
+		Base struct {
+			Ref string `json:"ref"`
+		} `json:"base"`
+	} `json:"pull_request"`
+	Repository struct {
+		Name  string `json:"name"`
+		Owner struct {
+			Login string `json:"login"`
+		} `json:"owner"`
+		HTMLURL string `json:"html_url"`
+	} `json:"repository"`
+	Sender struct {
+		Login string `json:"login"`
+	} `json:"sender"`
+}
+
+// PRWebhookEvent represents a parsed pull_request webhook event
+type PRWebhookEvent struct {
+	EventID     string
+	Platform    string
+	Action      string
+	Repository  Repository
+	PullRequest PRInfo
+	Sender      User
+}
+
+// PRInfo represents pull request information from pull_request event
+type PRInfo struct {
+	Number  int
+	State   string
+	Title   string
+	Draft   bool
+	Author  string
+	HeadRef string
+	HeadSHA string
+	BaseRef string
+}
+
 // GitLabWebhookPayload represents GitLab webhook payload structure
 type GitLabWebhookPayload struct {
 	ObjectKind       string `json:"object_kind"`
@@ -165,6 +219,63 @@ func ParseGitHubWebhook(payload []byte, eventType string) (*WebhookEvent, error)
 	return event, nil
 }
 
+// ParseGitHubPullRequestWebhook parses a GitHub pull_request webhook payload
+func ParseGitHubPullRequestWebhook(payload []byte, allowedActions []string) (*PRWebhookEvent, error) {
+	var ghPayload GitHubPullRequestPayload
+	if err := json.Unmarshal(payload, &ghPayload); err != nil {
+		return nil, fmt.Errorf("failed to parse GitHub pull_request payload: %w", err)
+	}
+
+	if err := validatePRAction(ghPayload.Action, allowedActions); err != nil {
+		return nil, err
+	}
+
+	if err := validateDraftPR(ghPayload.PullRequest.Draft, ghPayload.Action); err != nil {
+		return nil, err
+	}
+
+	event := &PRWebhookEvent{
+		Platform: "github",
+		Action:   ghPayload.Action,
+		Repository: Repository{
+			Owner: ghPayload.Repository.Owner.Login,
+			Name:  ghPayload.Repository.Name,
+			URL:   ghPayload.Repository.HTMLURL,
+		},
+		PullRequest: PRInfo{
+			Number:  ghPayload.PullRequest.Number,
+			State:   ghPayload.PullRequest.State,
+			Title:   ghPayload.PullRequest.Title,
+			Draft:   ghPayload.PullRequest.Draft,
+			Author:  ghPayload.PullRequest.User.Login,
+			HeadRef: ghPayload.PullRequest.Head.Ref,
+			HeadSHA: ghPayload.PullRequest.Head.SHA,
+			BaseRef: ghPayload.PullRequest.Base.Ref,
+		},
+		Sender: User{
+			Login: ghPayload.Sender.Login,
+		},
+	}
+
+	return event, nil
+}
+
+func validatePRAction(action string, allowedActions []string) error {
+	for _, allowed := range allowedActions {
+		if action == allowed {
+			return nil
+		}
+	}
+	return fmt.Errorf("action %q not in allowed actions", action)
+}
+
+func validateDraftPR(isDraft bool, action string) error {
+	if isDraft && action != "ready_for_review" {
+		return fmt.Errorf("skipping draft PR")
+	}
+	return nil
+}
+
 // ParseGitLabWebhook parses a GitLab webhook payload
 func ParseGitLabWebhook(payload []byte, eventType string) (*WebhookEvent, error) {
 	// Only process note events
diff --git a/pr-cli/pkg/webhook/parser_test.go b/pr-cli/pkg/webhook/parser_test.go
index 4b64026..c1336f0 100644
--- a/pr-cli/pkg/webhook/parser_test.go
+++ b/pr-cli/pkg/webhook/parser_test.go
@@ -376,3 +376,284 @@ func TestWebhookEventJSON(t *testing.T) {
 	assert.Equal(t, event.Repository.Owner, decoded.Repository.Owner)
 	assert.Equal(t, event.PullRequest.Number, decoded.PullRequest.Number)
 }
+
+func TestParseGitHubPullRequestWebhook(t *testing.T) {
+	tests := []struct {
+		name           string
+		payload        string
+		allowedActions []string
+		expectError    bool
+		errorContains  string
+		validate       func(t *testing.T, event *PRWebhookEvent)
+	}{
+		{
+			name: "valid opened PR event",
+			payload: `{
+				"action": "opened",
+				"number": 42,
+				"pull_request": {
+					"number": 42,
+					"state": "open",
+					"title": "Add new feature",
+					"draft": false,
+					"user": {
+						"login": "pr-author"
+					},
+					"head": {
+						"ref": "feature-branch",
+						"sha": "abc123def456"
+					},
+					"base": {
+						"ref": "main"
+					}
+				},
+				"repository": {
+					"name": "test-repo",
+					"html_url": "https://github.com/test-owner/test-repo",
+					"owner": {
+						"login": "test-owner"
+					}
+				},
+				"sender": {
+					"login": "pr-author"
+				}
+			}`,
+			allowedActions: []string{"opened", "synchronize"},
+			expectError:    false,
+			validate: func(t *testing.T, event *PRWebhookEvent) {
+				assert.Equal(t, "github", event.Platform)
+				assert.Equal(t, "opened", event.Action)
+				assert.Equal(t, 42, event.PullRequest.Number)
+				assert.Equal(t, "open", event.PullRequest.State)
+				assert.Equal(t, "Add new feature", event.PullRequest.Title)
+				assert.False(t, event.PullRequest.Draft)
+				assert.Equal(t, "pr-author", event.PullRequest.Author)
+				assert.Equal(t, "feature-branch", event.PullRequest.HeadRef)
+				assert.Equal(t, "abc123def456", event.PullRequest.HeadSHA)
+				assert.Equal(t, "main", event.PullRequest.BaseRef)
+				assert.Equal(t, "test-repo", event.Repository.Name)
+				assert.Equal(t, "test-owner", event.Repository.Owner)
+				assert.Equal(t, "pr-author", event.Sender.Login)
+			},
+		},
+		{
+			name: "valid synchronize PR event",
+			payload: `{
+				"action": "synchronize",
+				"number": 123,
+				"pull_request": {
+					"number": 123,
+					"state": "open",
+					"title": "Update feature",
+					"draft": false,
+					"user": {"login": "author"},
+					"head": {"ref": "feature", "sha": "newsha123"},
+					"base": {"ref": "main"}
+				},
+				"repository": {
+					"name": "repo",
+					"owner": {"login": "owner"}
+				},
+				"sender": {"login": "author"}
+			}`,
+			allowedActions: []string{"opened", "synchronize"},
+			expectError:    false,
+			validate: func(t *testing.T, event *PRWebhookEvent) {
+				assert.Equal(t, "synchronize", event.Action)
+				assert.Equal(t, 123, event.PullRequest.Number)
+				assert.Equal(t, "newsha123", event.PullRequest.HeadSHA)
+			},
+		},
+		{
+			name: "action not in allowed list",
+			payload: `{
+				"action": "closed",
+				"number": 1,
+				"pull_request": {
+					"number": 1,
+					"state": "closed",
+					"draft": false,
+					"user": {"login": "author"},
+					"head": {"ref": "feature", "sha": "sha"},
+					"base": {"ref": "main"}
+				},
+				"repository": {"name": "repo", "owner": {"login": "owner"}},
+				"sender": {"login": "author"}
+			}`,
+			allowedActions: []string{"opened", "synchronize"},
+			expectError:    true,
+			errorContains:  "not in allowed actions",
+		},
+		{
+			name: "draft PR should be skipped",
+			payload: `{
+				"action": "opened",
+				"number": 1,
+				"pull_request": {
+					"number": 1,
+					"state": "open",
+					"draft": true,
+					"user": {"login": "author"},
+					"head": {"ref": "feature", "sha": "sha"},
+					"base": {"ref": "main"}
+				},
+				"repository": {"name": "repo", "owner": {"login": "owner"}},
+				"sender": {"login": "author"}
+			}`,
+			allowedActions: []string{"opened", "synchronize"},
+			expectError:    true,
+			errorContains:  "draft PR",
+		},
+		{
+			name: "ready_for_review on draft PR should pass",
+			payload: `{
+				"action": "ready_for_review",
+				"number": 1,
+				"pull_request": {
+					"number": 1,
+					"state": "open",
+					"draft": true,
+					"user": {"login": "author"},
+					"head": {"ref": "feature", "sha": "sha"},
+					"base": {"ref": "main"}
+				},
+				"repository": {"name": "repo", "owner": {"login": "owner"}},
+				"sender": {"login": "author"}
+			}`,
+			allowedActions: []string{"ready_for_review"},
+			expectError:    false,
+			validate: func(t *testing.T, event *PRWebhookEvent) {
+				assert.Equal(t, "ready_for_review", event.Action)
+			},
+		},
+		{
+			name:           "invalid JSON payload",
+			payload:        `{invalid json`,
+			allowedActions: []string{"opened"},
+			expectError:    true,
+			errorContains:  "failed to parse",
+		},
+		{
+			name: "empty allowed actions",
+			payload: `{
+				"action": "opened",
+				"number": 1,
+				"pull_request": {
+					"number": 1,
+					"state": "open",
+					"draft": false,
+					"user": {"login": "author"},
+					"head": {"ref": "feature", "sha": "sha"},
+					"base": {"ref": "main"}
+				},
+				"repository": {"name": "repo", "owner": {"login": "owner"}},
+				"sender": {"login": "author"}
+			}`,
+			allowedActions: []string{},
+			expectError:    true,
+			errorContains:  "not in allowed actions",
+		},
+	}
+
+	for _, tt := range tests {
+		t.Run(tt.name, func(t *testing.T) {
+			event, err := ParseGitHubPullRequestWebhook([]byte(tt.payload), tt.allowedActions)
+			if tt.expectError {
+				assert.Error(t, err)
+				if tt.errorContains != "" {
+					assert.Contains(t, err.Error(), tt.errorContains)
+				}
+			} else {
+				require.NoError(t, err)
+				require.NotNil(t, event)
+				if tt.validate != nil {
+					tt.validate(t, event)
+				}
+			}
+		})
+	}
+}
+
+func TestValidatePRAction(t *testing.T) {
+	tests := []struct {
+		name           string
+		action         string
+		allowedActions []string
+		expectError    bool
+	}{
+		{
+			name:           "action allowed",
+			action:         "opened",
+			allowedActions: []string{"opened", "synchronize"},
+			expectError:    false,
+		},
+		{
+			name:           "action not allowed",
+			action:         "closed",
+			allowedActions: []string{"opened", "synchronize"},
+			expectError:    true,
+		},
+		{
+			name:           "empty allowed actions",
+			action:         "opened",
+			allowedActions: []string{},
+			expectError:    true,
+		},
+	}
+
+	for _, tt := range tests {
+		t.Run(tt.name, func(t *testing.T) {
+			err := validatePRAction(tt.action, tt.allowedActions)
+			if tt.expectError {
+				assert.Error(t, err)
+			} else {
+				assert.NoError(t, err)
+			}
+		})
+	}
+}
+
+func TestValidateDraftPR(t *testing.T) {
+	tests := []struct {
+		name        string
+		isDraft     bool
+		action      string
+		expectError bool
+	}{
+		{
+			name:        "non-draft PR any action",
+			isDraft:     false,
+			action:      "opened",
+			expectError: false,
+		},
+		{
+			name:        "draft PR with ready_for_review",
+			isDraft:     true,
+			action:      "ready_for_review",
+			expectError: false,
+		},
+		{
+			name:        "draft PR with other action",
+			isDraft:     true,
+			action:      "opened",
+			expectError: true,
+		},
+		{
+			name:        "draft PR with synchronize",
+			isDraft:     true,
+			action:      "synchronize",
+			expectError: true,
+		},
+	}
+
+	for _, tt := range tests {
+		t.Run(tt.name, func(t *testing.T) {
+			err := validateDraftPR(tt.isDraft, tt.action)
+			if tt.expectError {
+				assert.Error(t, err)
+			} else {
+				assert.NoError(t, err)
+			}
+		})
+	}
+}
```
