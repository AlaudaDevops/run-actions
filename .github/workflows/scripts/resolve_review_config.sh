#!/usr/bin/env bash
set -euo pipefail

REPO_INPUT="${REPO_INPUT:-}"
PROFILE_ROOT="${PROFILE_ROOT:-}"
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

PROFILE_FOUND=false
PROMPT_FILE="$DEFAULT_PROMPT_FILE"
SKILLS_ENABLED=true
SKILLS_FAIL_ON_SETUP_ERROR=false
SKILLS_REQUESTED=true
SKILLS_INCLUDE_JSON='["*"]'

if [[ ! "$REPO_NORMALIZED" =~ ^[a-z0-9_.-]+/[a-z0-9_.-]+$ ]]; then
  echo "⚠️ Invalid repository format '$REPO_INPUT'; skipping centralized profile lookup"
elif [ -d "$PROFILE_DIR" ]; then
  PROFILE_FOUND=true
else
  echo "ℹ️ No centralized profile found at $PROFILE_PATH"
fi

# Restrict prompt path to files inside the resolved profile directory.
if [[ "$PROMPT_FILE" == /* || "$PROMPT_FILE" == *".."* ]]; then
  echo "⚠️ Prompt file must be relative to profile dir. Falling back to $DEFAULT_PROMPT_FILE"
  PROMPT_FILE="$DEFAULT_PROMPT_FILE"
fi
PROMPT_FULL_PATH="${PROFILE_DIR}/${PROMPT_FILE}"
PROMPT_PATH="${PROFILE_PATH}/${PROMPT_FILE}"

DEFAULT_TEAM_NORMALIZED="$(echo "$DEFAULT_TEAM" | tr '[:upper:]' '[:lower:]')"
if [[ ! "$DEFAULT_TEAM_NORMALIZED" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "⚠️ Invalid DEFAULT_TEAM '$DEFAULT_TEAM'; falling back to devops"
  DEFAULT_TEAM_NORMALIZED="devops"
fi
SKILLS_TEAMS_JSON="$(jq -cn --arg team "$DEFAULT_TEAM_NORMALIZED" '[ $team ]')"
SKILLS_TEAMS_CSV="$DEFAULT_TEAM_NORMALIZED"

{
  echo "config_source=$CONFIG_SOURCE"
  echo "profile_ref=$PROFILE_REF"
  echo "profile_found=$PROFILE_FOUND"
  echo "profile_path=$PROFILE_PATH"
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
