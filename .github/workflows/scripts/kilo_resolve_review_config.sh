#!/usr/bin/env bash
set -euo pipefail

REPO_INPUT="${REPO_INPUT:-}"
PROFILE_ROOT="${PROFILE_ROOT:-}"
PROFILE_CONFIG_FILE="${PROFILE_CONFIG_FILE:-config.json}"
DEFAULT_PROMPT_FILE="${DEFAULT_PROMPT_FILE:-pr-review.md}"
DEFAULT_TEAM="${DEFAULT_TEAM:-devops}"
CONFIG_SOURCE="${CONFIG_SOURCE:-centralized}"
RUN_ACTIONS_DIR="${RUN_ACTIONS_DIR:-run-actions}"
PROFILE_REF_FALLBACK="${PROFILE_REF_FALLBACK:-unknown}"

if [ -z "${GITHUB_OUTPUT:-}" ]; then
  echo "❌ GITHUB_OUTPUT is required"
  exit 1
fi

if [ -z "$REPO_INPUT" ] || [ -z "$PROFILE_ROOT" ]; then
  echo "❌ REPO_INPUT and PROFILE_ROOT are required"
  exit 1
fi

PROFILE_REF="$(git -C "$RUN_ACTIONS_DIR" rev-parse HEAD 2>/dev/null || true)"
if [ -z "$PROFILE_REF" ]; then
  PROFILE_REF="$PROFILE_REF_FALLBACK"
fi

REPO_NORMALIZED="$(echo "$REPO_INPUT" | tr '[:upper:]' '[:lower:]')"
OWNER="${REPO_NORMALIZED%%/*}"
NAME="${REPO_NORMALIZED##*/}"
PROFILE_PATH="${PROFILE_ROOT}/${OWNER}/${NAME}"
PROFILE_DIR="${RUN_ACTIONS_DIR}/${PROFILE_PATH}"
CONFIG_PATH="${PROFILE_PATH}/${PROFILE_CONFIG_FILE}"
CONFIG_FILE="${PROFILE_DIR}/${PROFILE_CONFIG_FILE}"

# Defaults are safe fallbacks when config file is missing/invalid.
PROFILE_FOUND=false
HAS_REPO_CONFIG=false
PROMPT_FILE="$DEFAULT_PROMPT_FILE"
PROMPT_FULL_PATH="${PROFILE_DIR}/${PROMPT_FILE}"
PROMPT_PATH="${PROFILE_PATH}/${PROMPT_FILE}"
SKILLS_ENABLED=false
SKILLS_TEAMS_JSON="[]"
SKILLS_TEAMS_CSV=""
SKILLS_FAIL_ON_SETUP_ERROR=false
SKILLS_INCLUDE_JSON="[]"

if [[ ! "$REPO_NORMALIZED" =~ ^[a-z0-9_.-]+/[a-z0-9_.-]+$ ]]; then
  echo "⚠️ Invalid repository format '$REPO_INPUT'; skipping centralized profile lookup"
elif [ -d "$PROFILE_DIR" ]; then
  PROFILE_FOUND=true
else
  echo "ℹ️ No centralized profile found at $PROFILE_PATH"
fi

if [ "$PROFILE_FOUND" = "true" ] && [ -f "$CONFIG_FILE" ]; then
  if jq empty "$CONFIG_FILE" >/dev/null 2>&1; then
    HAS_REPO_CONFIG=true
    PROMPT_FILE="$(jq -r --arg default "$DEFAULT_PROMPT_FILE" '.prompt.path // $default' "$CONFIG_FILE")"
    SKILLS_ENABLED="$(jq -r '.skills.enabled // false' "$CONFIG_FILE")"
    SKILLS_TEAMS_JSON="$(jq -c '.skills.teams // []' "$CONFIG_FILE")"
    SKILLS_FAIL_ON_SETUP_ERROR="$(jq -r '.skills.fail_on_setup_error // false' "$CONFIG_FILE")"
    SKILLS_INCLUDE_JSON="$(jq -c '.skills.include // []' "$CONFIG_FILE")"
    echo "✅ Centralized config loaded from $CONFIG_PATH"
  else
    echo "⚠️ Failed to parse $CONFIG_PATH, using defaults"
  fi
elif [ "$PROFILE_FOUND" = "true" ]; then
  echo "ℹ️ No centralized config found at $CONFIG_PATH"
fi

if [ -z "$PROMPT_FILE" ] || [ "$PROMPT_FILE" = "null" ]; then
  PROMPT_FILE="$DEFAULT_PROMPT_FILE"
fi

# Restrict prompt path to files inside the resolved profile directory.
if [[ "$PROMPT_FILE" == /* || "$PROMPT_FILE" == *".."* ]]; then
  echo "⚠️ prompt.path must be a relative path inside profile dir. Falling back to $DEFAULT_PROMPT_FILE"
  PROMPT_FILE="$DEFAULT_PROMPT_FILE"
fi
PROMPT_FULL_PATH="${PROFILE_DIR}/${PROMPT_FILE}"
PROMPT_PATH="${PROFILE_PATH}/${PROMPT_FILE}"

case "$SKILLS_ENABLED" in
  true | false) ;;
  *) SKILLS_ENABLED=false ;;
esac

case "$SKILLS_FAIL_ON_SETUP_ERROR" in
  true | false) ;;
  *) SKILLS_FAIL_ON_SETUP_ERROR=false ;;
esac

# teams must be an array; this workflow intentionally does not support
# legacy skills.team (single string) anymore.
if ! echo "$SKILLS_TEAMS_JSON" | jq -e 'type == "array"' >/dev/null 2>&1; then
  SKILLS_TEAMS_JSON="[]"
fi
# Keep only safe, unique identifiers.
SKILLS_TEAMS_JSON="$(
  echo "$SKILLS_TEAMS_JSON" | jq -c '
    reduce .[] as $item
      ([];
        if ($item | type) == "string" then
          ($item | ascii_downcase) as $name
          | if ($name | test("^[a-z0-9][a-z0-9-]*$")) then
              if index($name) == null then . + [$name] else . end
            else . end
        else . end
      )
  '
)"

# include must be an array before we normalize entries.
if ! echo "$SKILLS_INCLUDE_JSON" | jq -e 'type == "array"' >/dev/null 2>&1; then
  SKILLS_INCLUDE_JSON="[]"
fi
# Keep only safe identifiers:
# - explicit skill names (lowercase + dash), e.g. "devops-task-overview-template"
# - wildcard "*" to include all discovered skills under CODEX_HOME/skills.
SKILLS_INCLUDE_JSON="$(
  echo "$SKILLS_INCLUDE_JSON" | jq -c '
    reduce .[] as $item
      ([];
        if ($item | type) == "string" then
          ($item | ascii_downcase) as $name
          | if ($name == "*" or ($name | test("^[a-z0-9][a-z0-9-]*$"))) then
              if index($name) == null then . + [$name] else . end
            else . end
        else . end
      )
  '
)"

SKILLS_REQUESTED=false
# teams is mandatory when skills are enabled.
if [ "$SKILLS_ENABLED" = "true" ] && [ "$(echo "$SKILLS_TEAMS_JSON" | jq 'length')" -eq 0 ]; then
  echo "⚠️ skills.teams must be a non-empty array when skills.enabled=true"
  if [ "$SKILLS_FAIL_ON_SETUP_ERROR" = "true" ]; then
    echo "❌ skills.fail_on_setup_error=true, stopping workflow"
    exit 1
  fi
  SKILLS_ENABLED=false
fi

# Skills are opt-in: we only bootstrap/load when explicitly enabled,
# teams is non-empty, and include list is non-empty.
# Set skills.include to ["*"] to load all discovered skills for the configured teams.
if [ "$SKILLS_ENABLED" = "true" ] && \
  [ "$(echo "$SKILLS_TEAMS_JSON" | jq 'length')" -gt 0 ] && \
  [ "$(echo "$SKILLS_INCLUDE_JSON" | jq 'length')" -gt 0 ]; then
  SKILLS_REQUESTED=true
fi

# When skills are disabled after validation, suppress teams metadata.
if [ "$SKILLS_ENABLED" != "true" ]; then
  SKILLS_TEAMS_JSON="[]"
fi
SKILLS_TEAMS_CSV="$(echo "$SKILLS_TEAMS_JSON" | jq -r 'join(", ")')"
if [ -z "$SKILLS_TEAMS_CSV" ]; then
  SKILLS_TEAMS_CSV="$DEFAULT_TEAM"
fi

# Export normalized config for downstream steps.
# Use heredoc form for JSON to preserve exact content.
{
  echo "config_source=$CONFIG_SOURCE"
  echo "profile_ref=$PROFILE_REF"
  echo "profile_found=$PROFILE_FOUND"
  echo "profile_path=$PROFILE_PATH"
  echo "has_repo_config=$HAS_REPO_CONFIG"
  echo "config_path=$CONFIG_PATH"
  echo "prompt_file=$PROMPT_FILE"
  echo "prompt_full_path=$PROMPT_FULL_PATH"
  echo "prompt_path=$PROMPT_PATH"
  echo "skills_enabled=$SKILLS_ENABLED"
  echo "skills_teams_csv=$SKILLS_TEAMS_CSV"
  echo "skills_fail_on_setup_error=$SKILLS_FAIL_ON_SETUP_ERROR"
  echo "skills_requested=$SKILLS_REQUESTED"
  echo "skills_teams_json<<EOF"
  echo "$SKILLS_TEAMS_JSON"
  echo "EOF"
  echo "skills_include_json<<EOF"
  echo "$SKILLS_INCLUDE_JSON"
  echo "EOF"
} >> "$GITHUB_OUTPUT"
