#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034
VERSION="2.0.7"
AUTHOR="raymon.epping"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

log_info()  { echo -e "ℹ️  $1"; }
log_warn()  { echo -e "⚠️  $1"; }
log_error() { echo -e "❌ $1"; exit 1; }

validate_flags() {
  local -n _flags_ref=$1
  local debug="${_flags_ref[debug]:-false}"
  local compact=false

  [[ "$debug" == "compact" ]] && compact=true && _flags_ref[debug]="true"

  VALID_FLAGS=(
    create 
    build 
    fresh 
    commit 
    request 
    quiet 
    status 
    language 
    scenario 
    debug 
    validate 
    version 
    help 
    repo_name 
    merge_main 
    yes 
    destroy 
    dry_run
  )

  # --- Dynamically load allowed languages and scenarios from input JSON
  local SCRIPTS_FOLDER="${SCRIPTS_FOLDER:-.}"
  local VAULT_INPUT_JSON="$SCRIPTS_FOLDER/vault_radar_input.json"

  if [[ -f "$VAULT_INPUT_JSON" ]]; then
    mapfile -t LANGUAGES < <(jq -r '.leaks[].languages[]' "$VAULT_INPUT_JSON" | sort -u)
    mapfile -t SCENARIOS < <(jq -r '.leaks[].scenario' "$VAULT_INPUT_JSON" | sort -u | tr '[:upper:]' '[:lower:]')
  else
    LANGUAGES=(bash docker node python terraform)
    SCENARIOS=(aws github inclusivity pii)
  fi

  # ✅ Unknown flag check (strict match)
  for key in "${!_flags_ref[@]}"; do
    if [[ ! " ${VALID_FLAGS[*]} " =~ (^|[[:space:]])$key($|[[:space:]]) ]]; then
      log_error "Unknown flag: --$key"
    fi
  done

  # ✅ Boolean validation (INCLUDES DRY_RUN!)
  for flag in create build fresh commit request quiet status yes dry_run; do
    _flags_ref[$flag]="${_flags_ref[$flag]:-false}"
    if [[ "${_flags_ref[$flag]}" != "true" && "${_flags_ref[$flag]}" != "false" ]]; then
      log_error "Invalid boolean for --$flag: ${_flags_ref[$flag]}"
    fi
  done

  # ✅ Safe defaulting (only if not set)
  [[ -z "${_flags_ref[language]:-}" ]] && _flags_ref[language]="bash"
  [[ -z "${_flags_ref[scenario]:-}" ]] && _flags_ref[scenario]="AWS"
  _flags_ref[debug]="${_flags_ref[debug]:-false}"

  # --- Language/scenario validation
  local language_lower scenario_lower
  language_lower="$(echo "${_flags_ref[language]}" | tr '[:upper:]' '[:lower:]')"
  scenario_lower="$(echo "${_flags_ref[scenario]}" | tr '[:upper:]' '[:lower:]')"

  if [[ ! " ${LANGUAGES[*]} " =~ (^|[[:space:]])${language_lower}($|[[:space:]]) ]]; then
    log_error "Invalid language: '${_flags_ref[language]}'. Supported: ${LANGUAGES[*]}"
  fi

  if [[ ! " ${SCENARIOS[*]} " =~ (^|[[:space:]])${scenario_lower}($|[[:space:]]) ]]; then
    log_error "Invalid scenario: '${_flags_ref[scenario]}'. Supported: ${SCENARIOS[*]}"
  fi

  # 🧠 Intelligent correction
  if [[ "${_flags_ref[build]}" != "true" && \
        ( "${language_lower}" != "bash" || "${scenario_lower}" != "aws" ) ]]; then
    log_warn "Explicit --language=${_flags_ref[language]} and/or --scenario=${_flags_ref[scenario]} given but --build=false"
    log_info "Auto-correcting: setting --build=true"
    _flags_ref[build]="true"
  fi

  # 🧨 DANGER ZONE: destroy mode validation 
  if [[ "${_flags_ref[destroy]:-false}" == "true" ]]; then
    if [[ -z "${_flags_ref[repo_name]:-}" ]]; then
      log_error "--repo-name is required when using destroy!"
    fi
  fi
}
