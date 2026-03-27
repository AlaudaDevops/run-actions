# Catalog Repository Review Guidelines

Focus this review on Tekton catalog quality, release safety, and operator compatibility.

## Scope Priorities

1. Correctness and safety of `Task` and `Pipeline` behavior.
2. Backward compatibility for existing params, results, and defaults.
3. Air-gap readiness (no hidden dependency on internet access).
4. Security and supply chain risk (image tags, script safety, secrets handling).

## Skill-Triggered Compliance Review

### Step 1 — Classify Changed Files

For each changed file in the PR diff, match it against the table below.
A skill activates only when **both** the file pattern matches **and** the content signal (if specified) is present somewhere in the diff for that file.

| Change Type | File Pattern | Content Signal (must appear in diff) | Skill to Activate |
|---|---|---|---|
| `task-manifest` | `task/**/*.yaml` with `kind: Task` | any change | `devops-tekton-task-generator` |
| `task-params-descriptors` | `task/**/*.yaml` or `pipeline/**/*.yaml` | `style.tekton.dev/descriptors`, `spec.params`, `displayParams`, or `integrations.tekton.dev` | `devops-tekton-dynamic-form-optimizer` |
| `task-results-overview` | `task/**/*.yaml` | `spec.results`, `overview-template-selector`, or `overview-template-result-key` | `devops-task-overview-template` |
| `overview-template` | `config/templates/**/*.yaml` | any change | `devops-task-overview-template` |
| `container-image` | `images/**/Containerfile` | any change | `devops-tekton-task-generator` (image conventions only) |
| `test-feature` | `**/features/**/*.feature` | any change | `devops-tekton-task-generator` (test conventions only) |
| `pac-pipeline` | `.tekton/**/*.yaml` | any change | `devops-tekton-task-generator` (PAC naming only) |
| `image-config` | `config/images/**/*.yaml` | any change | `devops-tekton-task-generator` (image config only) |

Collect the union of all activated skills across all changed files.

If no skill is activated, output `Skill compliance review not triggered.` and proceed with general checks only.

### Step 2 — Run Each Activated Skill

For each activated skill, apply the rules defined in that skill's `SKILL.md` to the relevant changed files.

When a change type narrows the scope (e.g., "image conventions only"), restrict the compliance check to that subset of the skill's rules — do not run the full skill.

### Step 3 — Report Findings

> **Advisory mode:** Skill compliance findings are informational only. They must NOT affect the `status` file output or block the PR from merging. Treat all skill findings as `WARNING` or lower regardless of their original severity.

Add a dedicated `## Skill Compliance` section to the review with the following structure:

```
## Skill Compliance

### Activated Skills
- <skill-name> (triggered by: <file-that-triggered-it>, change type: <type>)

### Findings

| Severity | File:Line | Checkpoint | Finding | Verdict |
|----------|-----------|------------|---------|---------|
| ERROR    | task/foo/0.1/foo.yaml:45 | runAsNonRoot required | securityContext missing | Fix code |
| WARNING  | task/foo/0.1/foo.yaml:12 | displayParams format | has trailing space | Fix code |
| WARNING  | config/templates/foo.yaml:8 | Array.isArray check | array iterated without guard | Update skill |

### Skipped Skills
- <skill-name> (reason: <why it was not triggered>)
```

**Verdict values:**
- `Fix code` — the change violates an established rule; the code needs to be corrected.
- `Update skill` — the change introduces a valid new pattern that the current skill rule does not cover; flag this for skill maintainers.
- `N/A` — the checkpoint is not applicable to this specific change.

If a skill has no findings, output a single `PASS` line instead of an empty table.

## Catalog-Specific General Checks

Apply these regardless of skill activation:

- **Backward compatibility** — params and results must not be silently renamed, removed, or repurposed.
- **Workspace compatibility** — `optional` flags on workspaces must not change in a breaking way.
- **Shell safety** — step scripts should use `set -eu`, proper quoting, and validate external inputs.
- **Air-gap compliance** — step scripts must not make runtime network calls to the internet.
- **Operator follow-up** — when Task params, results, or integration contracts change, note whether a corresponding operator-side update may be needed.

## Ignore / De-prioritize

- Generated files unless they indicate security or correctness risk.
- Cosmetic formatting-only updates with no runtime impact.
