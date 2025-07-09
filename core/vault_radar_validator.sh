#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034
VERSION="2.1.6"
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
    language # languages removed
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

  # --- Single language only!
  _flags_ref[language]="${_flags_ref[language]:-${_flags_ref[languages]:-bash}}"
  _flags_ref[language]="$(echo "${_flags_ref[language]}" | xargs | tr '[:upper:]' '[:lower:]')"
  if [[ "${_flags_ref[language]}" == *","* || "${_flags_ref[language]}" == *" "* ]]; then
    log_error "Only a single language is supported. Use --language with one value only."
  fi

  # Validate the single language
  local valid_lang=false
  for lang in "${LANGUAGES[@]}"; do
    [[ "${_flags_ref[language]}" == "${lang}" ]] && valid_lang=true && break
  done
  if [[ "$valid_lang" != "true" ]]; then
    log_error "Invalid language: '${_flags_ref[language]}'. Supported: ${LANGUAGES[*]}"
  fi

  # --- Multi-scenario allowed
  _flags_ref[scenarios]="${_flags_ref[scenarios]:-${_flags_ref[scenario]:-AWS}}"
  IFS=',' read -ra RAW_SCENARIOS <<< "${_flags_ref[scenarios]}"
  local -a SCENARIO_LIST=()
  for scen in "${RAW_SCENARIOS[@]}"; do
    scen_clean="$(echo "$scen" | xargs | tr '[:upper:]' '[:lower:]')"
    if [[ ! " ${SCENARIOS[*]} " =~ (^|[[:space:]])${scen_clean}($|[[:space:]]) ]]; then
      log_error "Invalid scenario: '$scen_clean'. Supported: ${SCENARIOS[*]}"
    fi
    SCENARIO_LIST+=("$scen_clean")
  done
  _flags_ref[scenarios]="${SCENARIO_LIST[*]}"

  # 🧠 Auto-correct: set build=true if scenario/language provided but build=false
  if [[ "${_flags_ref[build]}" != "true" && ( -n "${_flags_ref[language]}" || "${#SCENARIO_LIST[@]}" -gt 0 ) ]]; then
    log_warn "Explicit --language or --scenarios set, but --build=false"
    log_info "Auto-correcting: setting --build=true"
    _flags_ref[build]="true"
  fi

  # 🔥 destroy safety check
  if [[ "${_flags_ref[destroy]:-false}" == "true" && -z "${_flags_ref[repo_name]:-}" ]]; then
    log_error "--repo-name is required when using destroy!"
  fi
}
