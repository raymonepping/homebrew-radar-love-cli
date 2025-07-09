#!/usr/bin/env bash
set -euo pipefail

VERSION="2.1.4"
TMP_SUMMARY=""

# --- Robust temp cleanup on exit
trap '[[ -n "$TMP_SUMMARY" && -f "$TMP_SUMMARY" ]] && rm -f "$TMP_SUMMARY"' EXIT

# --- Logging function
log() {
  local level="${1:-info}" msg="${2:-}"
  case "$level" in
    step)   echo -e "➡️  $msg";;
    info)   echo -e "🟢 $msg";;
    warn)   echo -e "🟡 $msg";;
    error)  echo -e "🔴 $msg";;
    done)   echo -e "✅ $msg";;
    *)      echo -e "$msg";;
  esac
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [--input FILE] [--output FILE] [--template FILE] [--help] [--version]

Options:
  --input      JSON input file (default: vault_radar_input.json)
  --output     Markdown output file (default: vault-scenarios.md)
  --template   Markdown scenario template (default: vault_radar_scenarios.tpl)
  --help, -h   Show this help message and exit
  --version    Show script version and exit

Generates a rich Markdown scenario report from Vault Radar input.
EOF
}

# --- GitHub-flavored Markdown (GFM) anchor generator
make_gfm_anchor() {
  local anchor="$1"
  anchor="${anchor,,}"                             # lowercase
  anchor="${anchor// /-}"                          # spaces to dashes
  anchor=$(echo "$anchor" | tr -cd 'a-z0-9-_')     # keep only a-z, 0-9, - and _
  anchor=$(echo "$anchor" | sed -E 's/-+/-/g')     # collapse multiple dashes
  anchor="${anchor##-}"                            # trim leading dashes
  anchor="${anchor%%-}"                            # trim trailing dashes
  echo "$anchor"
}

parse_flags() {
  INPUT_JSON="vault_radar_input.json"
  OUTPUT="vault-scenarios.md"
  TEMPLATE="vault_radar_scenarios.tpl"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --input)
        INPUT_JSON="$2"; shift 2;;
      --output)
        OUTPUT="$2"; shift 2;;
      --template)
        TEMPLATE="$2"; shift 2;;
      --help|-h)
        show_help; exit 0;;
      --version)
        echo "$(basename "$0") version $VERSION"; exit 0;;
      *)
        log error "Unknown option: $1"; show_help; exit 1;;
    esac
  done
}

main() {
  log step "Parsing flags and setting up..."
  parse_flags "$@"

  log step "Checking jq dependency..."
  command -v jq >/dev/null 2>&1 || { log error "jq is required but not installed."; exit 1; }

  TMP_SUMMARY="$(mktemp)"

  # Emoji maps
  declare -A SEV_EMOJI=( [high]="🚨" [medium]="🟡" [low]="🟢" )
  declare -A CAT_EMOJI=( [secret]="🗝️" [pii]="📧" [non_inclusive]="🌈" )

  # Badges & Filters (all on one line, horizontal)
  local severity_badges category_badges
  severity_badges="[![](https://img.shields.io/badge/High-red)](#high) [![](https://img.shields.io/badge/Medium-yellow)](#medium) [![](https://img.shields.io/badge/Low-lightgrey)](#low)"
  category_badges="[![](https://img.shields.io/badge/Secret-purple)](#secret) [![](https://img.shields.io/badge/Pii-orange)](#pii) [![](https://img.shields.io/badge/Non%20inclusive-green)](#non-inclusive)"

  log info "Writing badge row and headers..."
  echo "# Vault Radar Scenarios" > "$OUTPUT"
  echo "" >> "$OUTPUT"
  echo "$severity_badges $category_badges" >> "$OUTPUT"
  echo "" >> "$OUTPUT"
  echo "---" >> "$OUTPUT"

  # Summary table
  log info "Generating summary table..."
  echo "| Label | Severity | Category | Languages |" >> "$OUTPUT"
  echo "|---|---|---|---|" >> "$OUTPUT"

  # Sort scenarios by category, then severity
  log step "Sorting and processing scenarios..."
  local scenarios length
  scenarios=$(jq -c '.leaks[]' "$INPUT_JSON" | jq -s 'sort_by(.category, .severity)')
  length=$(echo "$scenarios" | jq 'length')

  # ToC anchors and summary table
  declare -a ANCHORS
  for ((i=0; i<length; i++)); do
    local s label severity category languages anchor emoji cat_emoji
    s=$(echo "$scenarios" | jq -c ".[$i]")
    label=$(echo "$s" | jq -r '.label')
    severity=$(echo "$s" | jq -r '.severity')
    category=$(echo "$s" | jq -r '.category')
    scenario=$(echo "$s" | jq -r '.scenario')
    header_text="$label ($category / $scenario)"
    anchor=$(make_gfm_anchor "$header_text")
    languages=$(echo "$s" | jq -r '.languages | join(", ")')
    emoji="${SEV_EMOJI[$severity]}"
    cat_emoji="${CAT_EMOJI[$category]}"
    ANCHORS+=("$header_text|$anchor|$severity|$category|$languages")

    # summary table row
    echo "| [$header_text](#$anchor) | $emoji $severity | $cat_emoji $category | $languages |" >> "$TMP_SUMMARY"
  done

  cat "$TMP_SUMMARY" >> "$OUTPUT"
  echo -e "\n---\n" >> "$OUTPUT"

  # Collapsible sections by severity
  for sev in high medium low; do
    local sev_emoji
    sev_emoji="${SEV_EMOJI[$sev]}"
    echo "<details>" >> "$OUTPUT"
    echo "<summary>$sev_emoji <b>${sev^} Severity</b></summary>" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    for ((i=0; i<length; i++)); do
      local s label anchor value languages category author source demo_notes scenario cat_emoji sev_badge cat_badge header_text
      s=$(echo "$scenarios" | jq -c ".[$i]")
      [[ $(echo "$s" | jq -r '.severity') != "$sev" ]] && continue
      label=$(echo "$s" | jq -r '.label')
      category=$(echo "$s" | jq -r '.category')
      scenario=$(echo "$s" | jq -r '.scenario')
      header_text="$label ($category / $scenario)"
      anchor=$(make_gfm_anchor "$header_text")
      value=$(echo "$s" | jq -r '.value')
      languages=$(echo "$s" | jq -r '.languages | join(", ")')
      author=$(echo "$s" | jq -r '.author')
      source=$(echo "$s" | jq -r '.source')
      demo_notes=$(echo "$s" | jq -r '.demo_notes')
      cat_emoji="${CAT_EMOJI[$category]}"
      sev_badge="![](https://img.shields.io/badge/${sev^}-$sev-red)"
      cat_badge="![](https://img.shields.io/badge/${category^}-${category}-blue)"

      # Markdown output for this scenario
      cat <<EOM >> "$OUTPUT"
### $header_text ${SEV_EMOJI[$sev]}

- **Value:** \`$value\`
- **Languages:** $languages
- **Severity:** $sev $sev_badge
- **Category:** $category $cat_emoji $cat_badge
- **Author:** $author
- **Source:** $source

> $demo_notes

[⬆️ Back to top](#vault-radar-scenarios)

---
EOM
    done
    echo "</details>" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
  done
  log done "$OUTPUT generated"
}

main "$@"
