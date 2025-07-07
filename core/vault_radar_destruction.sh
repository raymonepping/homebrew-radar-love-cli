#!/usr/bin/env bash

set -euo pipefail
set -o errtrace

HELP_MSG="
Usage: vault_radar_destruction.sh --repo-name <REPO_NAME> [--force] [--quiet] [--yes] [--help]

Options:
  --repo-name  (required) Name of the repo to destroy (matches both GitHub and local folder)
  --force      Skip initial summary and double confirmation (NOT recommended!)
  --quiet      Suppress most output
  --yes        Auto-confirm (for automation/testing only)
  --help       Show this help message and exit
"

QUIET=false
FORCE=false
AUTO_YES=false
REPO_NAME=""

for arg in "$@"; do
  case "${arg,,}" in
    --help) echo "$HELP_MSG"; exit 0 ;;
    --quiet) QUIET=true ;;
    --force) FORCE=true ;;
    --yes) AUTO_YES=true ;;
    --repo-name)
      shift
      REPO_NAME="${1:-}";;
    --repo-name=*)
      REPO_NAME="${arg#*=}";;
  esac
done

note() {
  [[ "$QUIET" == true ]] && return
  echo -e "[NOTE] $*"
}
warn() {
  echo -e "\e[1;33m[WARN]\e[0m $*"
}
error() {
  echo -e "\e[1;31m[ERROR]\e[0m $*"
  exit 1
}

# --- 1. Require repo name ---
if [[ -z "$REPO_NAME" ]]; then
  error "You must specify --repo-name <REPO_NAME>"
fi

GITHUB_USER=$(gh api user | jq -r .login 2>/dev/null || echo "UNKNOWN")
GH_REPO="$GITHUB_USER/$REPO_NAME"
LOCAL_REPO_PATH="./$REPO_NAME"

# --- 2. Print summary ---
if [[ "$FORCE" == false ]]; then
  cat <<EOF

===========================================================================
 🚨 DANGER ZONE: Vault Radar Demo Destruction 🚨
===========================================================================

The following operations will be performed:

  - GitHub repository:  gh repo delete $GH_REPO
  - Local folder:       rm -rf $LOCAL_REPO_PATH

EOF
fi

# --- 3. Double confirmation unless --yes or --force ---
if [[ "$AUTO_YES" == false && "$FORCE" == false ]]; then
  warn "You are about to IRREVERSIBLY DELETE the GitHub repo and local folder."
  read -rp "Are you 100% sure you want to proceed? (type 'DESTROY' to continue): " CONFIRM1
  [[ "$CONFIRM1" != "DESTROY" ]] && { echo "Cancelled."; exit 1; }

  warn "Final warning: This CANNOT be undone. Type the repo name ($REPO_NAME) to confirm: "
  read -rp "Type repo name: " CONFIRM2
  [[ "$CONFIRM2" != "$REPO_NAME" ]] && { echo "Cancelled."; exit 1; }
fi

# --- 4. Remove GitHub repo ---
if gh repo view "$GH_REPO" &>/dev/null; then
  note "Deleting GitHub repository $GH_REPO..."
  gh repo delete "$GH_REPO" --yes --confirm || warn "Could not delete repo on GitHub."
else
  note "GitHub repo $GH_REPO does not exist or cannot be accessed."
fi

# --- 5. Remove local folder ---
if [[ -d "$LOCAL_REPO_PATH" ]]; then
  note "Deleting local folder $LOCAL_REPO_PATH..."
  rm -rf "$LOCAL_REPO_PATH"
else
  note "Local folder $LOCAL_REPO_PATH does not exist."
fi

# --- 6. Print summary ---
cat <<EOF

===========================================================================
 ✅ Destruction Complete

- GitHub repo attempted:  $GH_REPO
- Local folder deleted:   $LOCAL_REPO_PATH

If either failed, check permissions and retry manually.

===========================================================================

EOF

echo
echo "🌪️  The Vault Radar demo '${REPO_NAME}' has been erased from existence."
echo "🟢 Destruction verified — Wipe that tear away now from your eye."
