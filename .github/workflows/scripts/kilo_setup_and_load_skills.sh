#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"

if [ -z "${GITHUB_OUTPUT:-}" ]; then
  echo "❌ GITHUB_OUTPUT is required"
  exit 1
fi

join_csv() {
  if [ "$#" -eq 0 ]; then
    echo ""
    return 0
  fi
  printf '%s\n' "$@" | paste -sd ',' - | sed 's/,/, /g'
}

run_bootstrap() {
  # Prepare CODEX_HOME with Alauda AGENTS.md + skills in a disposable workspace.
  WORKDIR="${WORKDIR:-${RUNNER_TEMP:-/tmp}/alauda-ai-work}"
  TEAMS_JSON="${TEAMS_JSON:-[]}"
  TEAMS_CSV="${TEAMS_CSV:-}"
  FAIL_ON_SETUP="${FAIL_ON_SETUP:-false}"
  BASE_REPO="${BASE_REPO:-}"
  BUILDERS_REPO="${BUILDERS_REPO:-}"

  if [ -z "$BASE_REPO" ] || [ -z "$BUILDERS_REPO" ]; then
    echo "❌ BASE_REPO and BUILDERS_REPO are required for bootstrap mode"
    exit 1
  fi

  # Use a per-run temp workspace to avoid mutating checked-out repository files.
  rm -rf "$WORKDIR"
  mkdir -p "$WORKDIR"

  BOOTSTRAP_OK=true
  echo "📦 Cloning Alauda AI repositories for skills..."

  # Base repo provides setup script / core context; builders repo provides team content.
  if ! gh repo clone "$BASE_REPO" "$WORKDIR/alauda-ai-base"; then
    echo "⚠️ Failed to clone $BASE_REPO"
    BOOTSTRAP_OK=false
  fi

  if ! gh repo clone "$BUILDERS_REPO" "$WORKDIR/alauda-ai-builders"; then
    echo "⚠️ Failed to clone $BUILDERS_REPO"
    BOOTSTRAP_OK=false
  fi

  if [ "$BOOTSTRAP_OK" = "true" ]; then
    # setup.sh assembles CODEX_HOME content (AGENTS.md + skills) for all configured teams.
    declare -a TEAM_ARGS=()
    while IFS= read -r TEAM; do
      [ -z "$TEAM" ] && continue
      TEAM_ARGS+=(--team "$TEAM")
    done < <(echo "$TEAMS_JSON" | jq -r '.[]')

    if [ "${#TEAM_ARGS[@]}" -eq 0 ]; then
      echo "⚠️ No teams resolved for skills setup"
      BOOTSTRAP_OK=false
    elif ! (cd "$WORKDIR/alauda-ai-base" && ./setup.sh "${TEAM_ARGS[@]}" --dir "$WORKDIR"); then
      echo "⚠️ setup.sh failed for teams '$TEAMS_CSV'"
      BOOTSTRAP_OK=false
    fi
  fi

  CODEX_HOME="$WORKDIR/alauda-ai-config/.codex"
  SKILLS_DIR="$CODEX_HOME/skills"
  AGENTS_PATH="$CODEX_HOME/AGENTS.md"
  SKILLS_READY=false

  # Both AGENTS.md and skills directory must exist before enabling skills for this run.
  if [ "$BOOTSTRAP_OK" = "true" ] && [ -f "$AGENTS_PATH" ] && [ -d "$SKILLS_DIR" ]; then
    SKILLS_READY=true
    echo "✅ Alauda skill bootstrap ready"
  else
    # Default behavior is soft-fail to keep PR review available even when
    # internal skills cannot be prepared.
    echo "⚠️ Alauda skill bootstrap output incomplete; proceeding without internal skills"
    if [ "$FAIL_ON_SETUP" = "true" ]; then
      echo "❌ skills.fail_on_setup_error=true, stopping workflow"
      exit 1
    fi
  fi

  {
    echo "workdir=$WORKDIR"
    echo "codex_home=$CODEX_HOME"
    echo "skills_dir=$SKILLS_DIR"
    echo "agents_path=$AGENTS_PATH"
    echo "skills_ready=$SKILLS_READY"
  } >> "$GITHUB_OUTPUT"
}

run_load() {
  # Install selected skills into OpenCode's global native discovery path and expose
  # only a compact catalog (name + description) to the review prompt.
  INCLUDE_JSON="${INCLUDE_JSON:-[]}"
  SKILLS_DIR="${SKILLS_DIR:-}"
  TEAMS_CSV="${TEAMS_CSV:-}"
  FAIL_ON_SETUP="${FAIL_ON_SETUP:-false}"
  NATIVE_SKILLS_ROOT="${NATIVE_SKILLS_ROOT:-$HOME/.config/opencode/skills}"

  if [ -z "$SKILLS_DIR" ]; then
    echo "❌ SKILLS_DIR is required for load mode"
    exit 1
  fi

  mkdir -p "$NATIVE_SKILLS_ROOT"

  declare -a LOADED_SKILLS=()
  declare -a MISSING_SKILLS=()
  declare -a INSTALL_ERRORS=()
  INCLUDE_ALL=false

  # Wildcard mode: include all discovered skills from prepared CODEX_HOME.
  if echo "$INCLUDE_JSON" | jq -e 'index("*") != null' >/dev/null 2>&1; then
    INCLUDE_ALL=true
  fi

  # Manifest stores only user-facing routing metadata.
  echo "[]" > alauda_skills_manifest.json

  add_skill() {
    local SKILL_NAME="$1"
    local SKILL_SRC_DIR="$SKILLS_DIR/$SKILL_NAME"
    local SKILL_FILE="$SKILL_SRC_DIR/SKILL.md"
    local SKILL_DESC=""
    local DEST_DIR="$NATIVE_SKILLS_ROOT/$SKILL_NAME"

    if [ ! -f "$SKILL_FILE" ]; then
      echo "⚠️ Requested skill not found: $SKILL_NAME"
      MISSING_SKILLS+=("$SKILL_NAME")
      return 0
    fi

    rm -rf "$DEST_DIR"
    if ! cp -R "$SKILL_SRC_DIR" "$DEST_DIR"; then
      echo "⚠️ Failed to install skill into native path: $SKILL_NAME"
      INSTALL_ERRORS+=("$SKILL_NAME")
      return 0
    fi

    SKILL_DESC="$(awk '
      {
        line=$0
        gsub(/\r/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        if (line == "" || line ~ /^#/) next
        print line
        exit
      }
    ' "$SKILL_FILE")"
    if [ -z "$SKILL_DESC" ]; then
      SKILL_DESC="No description provided."
    fi

    LOADED_SKILLS+=("$SKILL_NAME")
    jq --arg name "$SKILL_NAME" --arg description "$SKILL_DESC" '. += [{"name": $name, "description": $description}]' \
      alauda_skills_manifest.json > alauda_skills_manifest.tmp
    mv alauda_skills_manifest.tmp alauda_skills_manifest.json
  }

  if [ "$INCLUDE_ALL" = "true" ]; then
    # Keep deterministic order so prompt output remains stable across runs.
    while IFS= read -r SKILL_FILE; do
      [ -z "$SKILL_FILE" ] && continue
      SKILL_NAME="$(basename "$(dirname "$SKILL_FILE")")"
      add_skill "$SKILL_NAME"
    done < <(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -type f -name 'SKILL.md' | LC_ALL=C sort)
  else
    # Explicit mode: load only whitelisted skills, report missing entries.
    while IFS= read -r SKILL_NAME; do
      [ -z "$SKILL_NAME" ] && continue
      add_skill "$SKILL_NAME"
    done < <(echo "$INCLUDE_JSON" | jq -r '.[]')
  fi

  HAS_ALAUDA_SKILLS=false
  LOADED_SKILLS_CSV=""
  MISSING_SKILLS_CSV=""
  LOADED_SKILLS_JSON="[]"

  if [ "${#INSTALL_ERRORS[@]}" -gt 0 ]; then
    INSTALL_ERRORS_CSV="$(join_csv "${INSTALL_ERRORS[@]}")"
    echo "⚠️ Failed to install skills into native path: $INSTALL_ERRORS_CSV"
    if [ "$FAIL_ON_SETUP" = "true" ]; then
      echo "❌ skills.fail_on_setup_error=true, stopping workflow"
      exit 1
    fi
  fi

  if [ "${#LOADED_SKILLS[@]}" -gt 0 ]; then
    # Verify runtime skill discovery to ensure OpenCode can resolve installed skills.
    if opencode debug skill > opencode_skills_discovery.json 2>/dev/null; then
      VISIBLE_SKILLS_JSON="$(
        jq -c --arg root "$NATIVE_SKILLS_ROOT/" '
          [.[] | select((.location // "") | startswith($root)) | .name] | unique | sort
        ' opencode_skills_discovery.json 2>/dev/null || echo "[]"
      )"
      if ! echo "$VISIBLE_SKILLS_JSON" | jq -e 'type == "array"' >/dev/null 2>&1; then
        VISIBLE_SKILLS_JSON="[]"
      fi

      EXPECTED_SKILLS_JSON="$(printf '%s\n' "${LOADED_SKILLS[@]}" | jq -R . | jq -c -s 'unique | sort')"
      MISSING_RUNTIME_JSON="$(jq -cn --argjson expected "$EXPECTED_SKILLS_JSON" --argjson visible "$VISIBLE_SKILLS_JSON" '$expected - $visible')"
      if [ "$(echo "$MISSING_RUNTIME_JSON" | jq 'length')" -gt 0 ]; then
        MISSING_RUNTIME_CSV="$(echo "$MISSING_RUNTIME_JSON" | jq -r 'join(", ")')"
        echo "⚠️ Native skill discovery missing: $MISSING_RUNTIME_CSV"
        if [ "$FAIL_ON_SETUP" = "true" ]; then
          echo "❌ skills.fail_on_setup_error=true, stopping workflow"
          exit 1
        fi
      fi

      # Keep only skills that OpenCode actually discovers in native path.
      jq --argjson visible "$VISIBLE_SKILLS_JSON" '
        [.[] | select(.name as $n | $visible | index($n) != null)]
      ' alauda_skills_manifest.json > alauda_skills_manifest.tmp
      mv alauda_skills_manifest.tmp alauda_skills_manifest.json
    else
      echo "⚠️ Failed to run 'opencode debug skill'"
      if [ "$FAIL_ON_SETUP" = "true" ]; then
        echo "❌ skills.fail_on_setup_error=true, stopping workflow"
        exit 1
      fi
      echo "[]" > alauda_skills_manifest.json
    fi
  fi

  if [ "$(jq 'length' alauda_skills_manifest.json)" -gt 0 ]; then
    HAS_ALAUDA_SKILLS=true
    LOADED_SKILLS_CSV="$(jq -r '.[].name' alauda_skills_manifest.json | paste -sd ',' - | sed 's/,/, /g')"
    LOADED_SKILLS_JSON="$(jq -c '[.[].name]' alauda_skills_manifest.json)"
    cat > alauda_skills_prompt.md << EOF
Teams: $TEAMS_CSV
The following Alauda internal skills are available for this review.
Use skill names as routing hints. Fetch full skill content only when relevant via the native skill tool.
Do not copy internal policy text verbatim into public PR comments.

EOF
    jq -r '.[] | "- \(.name): \(.description)"' alauda_skills_manifest.json >> alauda_skills_prompt.md
    echo "✅ Loaded Alauda skills: $LOADED_SKILLS_CSV"
  else
    echo "⚠️ No Alauda skills were loaded"
  fi

  if [ "${#MISSING_SKILLS[@]}" -gt 0 ]; then
    MISSING_SKILLS_CSV="$(join_csv "${MISSING_SKILLS[@]}")"
    # Strict mode: treat missing explicitly requested skills as hard failure.
    if [ "$FAIL_ON_SETUP" = "true" ]; then
      echo "❌ Missing required skills: $MISSING_SKILLS_CSV"
      exit 1
    fi
  fi

  # Expose load results for prompt composition and review metadata.
  {
    echo "has_alauda_skills=$HAS_ALAUDA_SKILLS"
    echo "loaded_skills=$LOADED_SKILLS_CSV"
    echo "loaded_skills_json=$LOADED_SKILLS_JSON"
    echo "missing_skills=$MISSING_SKILLS_CSV"
    echo "native_skills_root=$NATIVE_SKILLS_ROOT"
  } >> "$GITHUB_OUTPUT"
}

case "$MODE" in
  bootstrap)
    run_bootstrap
    ;;
  load)
    run_load
    ;;
  *)
    echo "❌ Usage: $0 <bootstrap|load>"
    exit 1
    ;;
esac
