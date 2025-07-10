#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034
VERSION="2.8.3"

# --- Find the base/core script folder ---
if [[ -n "${RADAR_LOVE_HOME:-}" && -d "$RADAR_LOVE_HOME/core" ]]; then
  SCRIPTS_FOLDER="$RADAR_LOVE_HOME/core"
elif command -v brew &>/dev/null && HOMEBREW_PREFIX="$(brew --prefix radar-love-cli 2>/dev/null)" && [[ -d "$HOMEBREW_PREFIX/share/radar-love-cli/core" ]]; then
  SCRIPTS_FOLDER="$HOMEBREW_PREFIX/share/radar-love-cli/core"
else
  SCRIPTS_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Colors
color_red=$'\e[31m'
color_green=$'\e[32m'
color_blue=$'\e[34m'
color_yellow=$'\e[33m'
color_bold=$'\e[1m'
color_reset=$'\e[0m'

# Safe positional variable
ARG1="${1:-}"

# Parse --dry-run from CLI args
DRY_RUN="false"
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then
    DRY_RUN="true"
    break
  fi
done

# Source the helper (relative to SCRIPTS_FOLDER for maximum reliability!)
source "$SCRIPTS_FOLDER/vault_radar_quotes_helper.sh"

main_decision_tree() {
  # 1. Validate environment
  "$SCRIPTS_FOLDER/validate_env.sh" --quiet || { echo "Please install required tools."; exit 1; }

  # 2. Pick a random band for this session
  BAND=$(pick_random_band)
  echo ""
  echo "🎸 Today’s band for quotes is: $BAND"

  # 3. Welcome message (stage: start)
  START_QUOTE=$(pick_quote "$BAND" "start")
  echo -e "\n$START_QUOTE\n"

  # --- Top-level choices (zero prompt or interactive as fallback)
  echo "Do you want to create a new project? (Y/n)"
  read -r CREATE
  if [[ -z "${CREATE}" || "${CREATE,,}" =~ ^(y|yes)$ ]]; then
    echo
    echo "Enter project name (leave blank for random):"
    echo "⚠️  Only letters, numbers, spaces, and dashes are supported. Everything else will be removed."
    read -r RAW_NAME
    if [[ -z "$RAW_NAME" ]]; then
      RAW_NAME=$(jq -r --arg band "$BAND" '.[] | select(.band == $band) | .entries[] | select(.stage|index("creation")) | .name' "$QUOTES_FILE" | shuf -n 1)
      echo -n "Random project name picked: "
      echo -e "${color_red}${RAW_NAME}${color_reset}"
    fi
    REPO_NAME=$(to_title_kebab_case "$RAW_NAME")
    echo -n "Using repo name: "
    echo -e "${color_yellow}${REPO_NAME}${color_reset}"

    CREATION_QUOTE=$(pick_quote "$BAND" "creation")
    echo "🎤 $CREATION_QUOTE"

    # --- Dynamically load valid language and scenarios from input file
    VAULT_INPUT_JSON="$SCRIPTS_FOLDER/vault_radar_input.json"
    if [[ -f "$VAULT_INPUT_JSON" ]]; then
      mapfile -t LANGUAGES < <(jq -r '.leaks[].languages[]' "$VAULT_INPUT_JSON" | sort -u)
      mapfile -t SCENARIOS < <(jq -r '.leaks[].scenario' "$VAULT_INPUT_JSON" | tr '[:upper:]' '[:lower:]' | sort -u)
    else
      LANGUAGES=(bash docker node python terraform)
      SCENARIOS=(aws github inclusivity pii)
    fi

    # --- Language: single select only; --languages alias handled by CLI entrypoint.
    echo
    echo "Available languages: ${LANGUAGES[*]}"
    while :; do
      echo "Enter language (single value):"
      read -r LANGUAGE_INPUT
      LANGUAGE_INPUT="$(echo "$LANGUAGE_INPUT" | xargs | tr '[:upper:]' '[:lower:]')"
      if [[ -z "$LANGUAGE_INPUT" ]]; then
        echo -e "${color_red}❌ Please enter a language.${color_reset}"
        continue
      fi
      if [[ ! " ${LANGUAGES[*],,} " =~ (^|[[:space:]])${LANGUAGE_INPUT}($|[[:space:]]) ]]; then
        echo -e "${color_red}❌ Invalid language: '$LANGUAGE_INPUT'. Valid options: ${LANGUAGES[*]}${color_reset}"
        continue
      fi
      break
    done

    # --- Scenario multi-selection
    echo
    echo "Available scenarios: ${SCENARIOS[*]}"
    echo "Enter one or more scenarios (comma-separated):"
    read -r SCENARIO_INPUT_RAW
    SCENARIO_INPUT_RAW="$(echo "$SCENARIO_INPUT_RAW" | xargs)"
    IFS=',' read -ra SCENARIO_ARRAY <<< "$(echo "$SCENARIO_INPUT_RAW" | tr '[:upper:]' '[:lower:]')"

    # Validate
    VALID_SCNS_LOWER=("${SCENARIOS[@]}")
    for scn in "${SCENARIO_ARRAY[@]}"; do
      if [[ ! " ${VALID_SCNS_LOWER[*]} " =~ (^|[[:space:]])$scn($|[[:space:]]) ]]; then
        echo -e "${color_red}❌ Invalid scenario: '$scn'. Valid options: ${SCENARIOS[*]}${color_reset}"
        exit 1
      fi
    done

    # Prompt for additional steps
    echo
    echo "Do you want to auto-commit after building? (Y/n)"
    read -r COMMIT
    [[ -z "${COMMIT}" || "${COMMIT,,}" =~ ^(y|yes)$ ]] && DO_COMMIT="true" || DO_COMMIT="false"
    echo

    echo "Do you want to trigger a PR scan after commit? (Y/n)"
    read -r TRIGGER
    [[ -z "${TRIGGER}" || "${TRIGGER,,}" =~ ^(y|yes)$ ]] && DO_TRIGGER="true" || DO_TRIGGER="false"
    echo

    echo "Do you want to auto-merge the leaky demo branch into main? (Y/n)"
    read -r MERGE
    [[ -z "${MERGE}" || "${MERGE,,}" =~ ^(y|yes)$ ]] && DO_MERGE="--merge-main" && MERGE_YESNO="yes" || { DO_MERGE=""; MERGE_YESNO="no"; }
    echo

    # Summary
    echo "🚦 Summary:"
    printf "  %-15s %s\n" "Repo name:"    "${color_green}${REPO_NAME}${color_reset}"
    printf "  %-15s %s\n" "Language:"     "${LANGUAGE_INPUT}"
    printf "  %-15s %s\n" "Scenario(s):"  "${SCENARIO_ARRAY[*]}"
    printf "  %-15s %s\n" "Commit:"       "$DO_COMMIT"
    printf "  %-15s %s\n" "Trigger PR:"   "$DO_TRIGGER"
    printf "  %-15s %s\n" "Merge branch:" "$MERGE_YESNO"
    echo

    # Compose the command to show/run
    echo -e "\n🧩 Preparing to run combination:\n"
    SCENARIO_CSV=$(IFS=','; echo "${SCENARIO_ARRAY[*]}")
    echo -e "🔧 ${color_blue}${REPO_NAME}${color_reset} → $LANGUAGE_INPUT + $SCENARIO_CSV"
    CMD="radar_love --create true --repo-name \"$REPO_NAME\" --build true --language \"$LANGUAGE_INPUT\" --scenarios \"$SCENARIO_CSV\" --commit $DO_COMMIT --request $DO_TRIGGER $DO_MERGE"
    [[ "$DRY_RUN" == "true" ]] && CMD="$CMD --dry-run"
    echo "Would run: ${color_blue}${CMD}${color_reset}"
    echo

    # Final confirmation before running
    echo -n "Would you like to run the above command now? (Y/n) "
    read -r FINAL_CONFIRM
    if [[ -z "${FINAL_CONFIRM}" || "${FINAL_CONFIRM,,}" =~ ^(y|yes)$ ]]; then
      echo -e "\n🚀 Running: ${color_blue}${CMD}${color_reset}\n"
      eval "$CMD"
    else
      echo "🚦 Skipped execution. No changes made."
      exit 0
    fi
  fi
} # <--- THIS LINE CLOSES THE FUNCTION PROPERLY!

# Entry point logic, outside function!
if [[ "${1:-}" == "--test" ]]; then
  main_decision_tree
else
  main_decision_tree "$@"
fi
