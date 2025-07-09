#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034
VERSION="2.1.2"
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
    repo_name create fresh build  
    language languages 
    scenario scenarios
    commit request merge_main status
    quiet debug validate version help
    yes destroy dry_run
  )

  local SCRIPTS_FOLDER="${SCRIPTS_FOLDER:-.}"
  local VAULT_INPUT_JSON="$SCRIPTS_FOLDER/vault_radar_input.json"

  if [[ -f "$VAULT_INPUT_JSON" ]]; then
    mapfile -t LANGUAGES < <(jq -r '.leaks[].languages[]' "$VAULT_INPUT_JSON" | sort -u)
    mapfile -t SCENARIOS < <(jq -r '.leaks[].scenario' "$VAULT_INPUT_JSON" | sort -u | tr '[:upper:]' '[:lower:]')
  else
    LANGUAGES=(bash docker node python terraform)
    SCENARIOS=(aws github inclusivity pii)
  fi

  # ✅ Check for unknown flags
  for key in "${!_flags_ref[@]}"; do
    if [[ ! " ${VALID_FLAGS[*]} " =~ (^|[[:space:]])$key($|[[:space:]]) ]]; then
      log_error "Unknown flag: --$key"
    fi
  done

  # ✅ Validate boolean flags
  for flag in create build fresh commit request quiet status yes dry_run; do
    _flags_ref[$flag]="${_flags_ref[$flag]:-false}"
    if [[ "${_flags_ref[$flag]}" != "true" && "${_flags_ref[$flag]}" != "false" ]]; then
      log_error "Invalid boolean for --$flag: ${_flags_ref[$flag]}"
    fi
  done

  # --- Sanitize multi-value flags
  _flags_ref[languages]="${_flags_ref[languages]:-${_flags_ref[language]:-bash}}"
  _flags_ref[scenarios]="${_flags_ref[scenarios]:-${_flags_ref[scenario]:-AWS}}"

  local -a LANGUAGE_LIST=()
  local -a SCENARIO_LIST=()

  IFS=',' read -ra RAW_LANGUAGES <<< "${_flags_ref[languages]}"
  IFS=',' read -ra RAW_SCENARIOS <<< "${_flags_ref[scenarios]}"

  for lang in "${RAW_LANGUAGES[@]}"; do
    lang_clean="$(echo "$lang" | xargs | tr '[:upper:]' '[:lower:]')"
    if [[ ! " ${LANGUAGES[*]} " =~ (^|[[:space:]])${lang_clean}($|[[:space:]]) ]]; then
      log_error "Invalid language: '$lang_clean'. Supported: ${LANGUAGES[*]}"
    fi
    LANGUAGE_LIST+=("$lang_clean")
  done

  for scen in "${RAW_SCENARIOS[@]}"; do
    scen_clean="$(echo "$scen" | xargs | tr '[:upper:]' '[:lower:]')"
    if [[ ! " ${SCENARIOS[*]} " =~ (^|[[:space:]])${scen_clean}($|[[:space:]]) ]]; then
      log_error "Invalid scenario: '$scen_clean'. Supported: ${SCENARIOS[*]}"
    fi
    SCENARIO_LIST+=("$scen_clean")
  done

  # Store validated lists back into flags
  _flags_ref[languages]="${LANGUAGE_LIST[*]}"
  _flags_ref[scenarios]="${SCENARIO_LIST[*]}"

  # 🧠 Auto-correct: set build=true if scenario/language provided but build=false
  if [[ "${_flags_ref[build]}" != "true" && ( "${#LANGUAGE_LIST[@]}" -gt 0 || "${#SCENARIO_LIST[@]}" -gt 0 ) ]]; then
    log_warn "Explicit --languages or --scenarios set, but --build=false"
    log_info "Auto-correcting: setting --build=true"
    _flags_ref[build]="true"
  fi

  # 🔥 destroy safety check
  if [[ "${_flags_ref[destroy]:-false}" == "true" && -z "${_flags_ref[repo_name]:-}" ]]; then
    log_error "--repo-name is required when using destroy!"
  fi
}
