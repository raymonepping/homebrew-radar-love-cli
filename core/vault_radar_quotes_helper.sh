#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034
VERSION="2.5.0"

# If QUOTES_FILE is set in the environment, use it. Otherwise, try to resolve relative to *this* script.
if [[ -z "${QUOTES_FILE:-}" ]]; then
  # BASH_SOURCE[0] works even when sourced, giving the file path of this script.
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  QUOTES_FILE="$SCRIPT_DIR/vault_radar_quotes.json"
fi

# Simple snake_case helper for repo names
to_title_kebab_case() {
  # Remove all but letters, numbers, spaces, dashes
  echo "$1" |
    tr -cd '[:alnum:] -\n' | \
    sed 's/  */ /g' | \
    sed 's/^-*//' | sed 's/-*$//' | \
    sed 's/ *- */-/g' | \
    awk -F'-| ' '{
      out="";
      for (i=1;i<=NF;i++) {
        if (length($i)) {
          word = toupper(substr($i,1,1)) tolower(substr($i,2));
          out = out (out ? "-" : "") word;
        }
      }
      print out
    }'
}

to_title_snake_case() {
  # Converts a string to Title_Snake (e.g. "live forever" -> "Live_Forever")
  echo "$1" | \
    tr -cd '[:alnum:] \n' | \
    sed 's/  */ /g' | \
    awk '{ for(i=1;i<=NF;i++) { $i=toupper(substr($i,1,1)) tolower(substr($i,2)) } print }' | \
    tr ' ' '_'
}
to_snake_case() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:] _-' | tr ' ' '_' | tr '-' '_'
}

# -- Band helpers --
list_bands() {
  jq -r '.[].band' "$QUOTES_FILE"
}

pick_random_band() {
  list_bands | shuf -n 1
}

# -- Stage helpers --
list_stages() {
  jq -r '[.[] | .entries[] | .stage[]] | unique[]' "$QUOTES_FILE"
}

pick_random_stage_for_band() {
  local band="$1"
  jq -r --arg band "$band" '.[] | select(.band == $band) | .entries[] | .stage[]' "$QUOTES_FILE" | sort | uniq | shuf -n 1
}

# -- Quote helpers --
list_quotes() {
  local band="$1"
  local stage="$2"
  jq -r --arg band "$band" --arg stage "$stage" \
    '.[] | select(.band == $band) | .entries[]
      | select(.stage | index($stage))
      | "\(.name): \(.quote)"' "$QUOTES_FILE"
}

pick_quote() {
  local band="$1"
  local stage="$2"
  jq -r --arg band "$band" --arg stage "$stage" \
    '.[] | select(.band == $band) | .entries[]
      | select(.stage | index($stage))
      | .quote' "$QUOTES_FILE" | shuf -n 1
}

# --- Test function ---
test_band_quotes_helper() {
  echo "Bands:"
  list_bands | nl

  echo -e "\nStages:"
  list_stages | nl

  # Try random band and stage
  local band stage
  band=$(pick_random_band)
  stage=$(pick_random_stage_for_band "$band")
  echo -e "\nPicked: $band / $stage"
  echo "Quote:"
  pick_quote "$band" "$stage"

  echo -e "\nAll quotes for Oasis/creation:"
  list_quotes "Oasis" "creation"
}

if [[ "${1:-}" == "--test" ]]; then
  test_band_quotes_helper
fi
