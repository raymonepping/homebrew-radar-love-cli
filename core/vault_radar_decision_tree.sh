#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034
VERSION="1.7.16"

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

  # 4. Top-level choices (zero prompt or interactive as fallback)
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

    # Prompt for additional steps, with a line break after each answer
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
    printf "  Repo name:    ${color_green}%s${color_reset}\n" "$REPO_NAME"
    echo "  Commit:       $DO_COMMIT"
    echo "  Trigger PR:   $DO_TRIGGER"
    echo "  Merge branch: $MERGE_YESNO"
    echo

    # Compose the command to show/run
    RADAR_CMD="radar_love --create true --repo-name \"$REPO_NAME\" --build true --commit $DO_COMMIT --request $DO_TRIGGER $DO_MERGE"
    [[ "$DRY_RUN" == "true" ]] && RADAR_CMD="$RADAR_CMD --dry-run"

    echo "Would now run:"
    echo -e "${color_blue}${RADAR_CMD}${color_reset}"
    echo

    # Final confirmation before running
    echo -n "Would you like to run this command now? (Y/n) "
    read -r FINAL_CONFIRM
    if [[ -z "${FINAL_CONFIRM}" || "${FINAL_CONFIRM,,}" =~ ^(y|yes)$ ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${color_yellow}Dry-run enabled. No changes will be made.${color_reset}"
        exit 0
      else
        echo -e "${color_blue}Running radar_love...${color_reset}"
        eval "$RADAR_CMD"
      fi
    else
      echo "🚦 Skipped execution. No changes made."
      exit 0
    fi

  else
    echo "Exiting!"
    exit 0
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  main_decision_tree
else
  main_decision_tree "$@"
fi
