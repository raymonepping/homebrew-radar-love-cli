#!/usr/bin/env bash
set -euo pipefail
# Vault_Radar_builder.sh
# Generate realistic "leak" scripts for Vault Radar demo/testing.

VERSION="2.8.3"
AUTHOR="raymon.epping"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
RUNID="$(date +%s)-$RANDOM"

# --- Defaults ---
INPUT="Vault_Radar_input.json"
OUTDIR="radar_demo"
LANGS_TO_GEN="all"         # --language is normalized by entrypoint; never --languages
SCENARIO=""
HEADER_TEMPLATE="templates/header.tpl"
FOOTER_TEMPLATE="templates/footer.tpl"
LOGFILE="$OUTDIR/Vault_Radar_build.log"
CLEANUP_SCRIPT="$OUTDIR/Vault_Radar_cleanup.sh"
LINT=0
DRYRUN=0
QUIET=0

usage() {
  cat <<EOF
Vault_Radar_builder.sh [options]
  --output-path DIR         Output directory (default: ./radar_demo)
  --language LANG           Output only these (comma-separated): bash,python,node,docker,terraform,md
  --scenario SCENARIO       Filter leaks for a specific scenario (e.g., AWS)
  --header-template FILE    Custom header template file
  --footer-template FILE    Custom footer template file
  --lint                    Run sanity_check.sh if available
  --dry-run                 Preview only, do not write files
  --quiet                   Suppress standard output (errors/warnings only)
  --help                    This help
  --version                 Show script version
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --output-path) OUTDIR="$2"; shift 2 ;;
    --language) LANGS_TO_GEN="$2"; shift 2 ;;
    --scenario) SCENARIO="$2"; shift 2 ;;
    --header-template) HEADER_TEMPLATE="$2"; shift 2 ;;
    --footer-template) FOOTER_TEMPLATE="$2"; shift 2 ;;
    --lint) LINT=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --help) usage; exit 0 ;;
    --version) echo "Vault_Radar_builder.sh v$VERSION"; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# --- Template path resolution (Homebrew, RADAR_LOVE_HOME, local dev) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Make template paths absolute if needed
[[ ! "$HEADER_TEMPLATE" =~ ^/ ]] && HEADER_TEMPLATE="$SCRIPT_DIR/$HEADER_TEMPLATE"
[[ ! "$FOOTER_TEMPLATE" =~ ^/ ]] && FOOTER_TEMPLATE="$SCRIPT_DIR/$FOOTER_TEMPLATE"

# Resolve header template
if [[ ! -f "$HEADER_TEMPLATE" ]]; then
  if [[ -n "${RADAR_LOVE_HOME:-}" && -f "$RADAR_LOVE_HOME/templates/header.tpl" ]]; then
    HEADER_TEMPLATE="$RADAR_LOVE_HOME/templates/header.tpl"
  elif command -v brew &>/dev/null && HOMEBREW_PREFIX="$(brew --prefix radar_love_cli 2>/dev/null)" && [[ -f "$HOMEBREW_PREFIX/templates/header.tpl" ]]; then
    HEADER_TEMPLATE="$HOMEBREW_PREFIX/templates/header.tpl"
  elif [[ -f "$PARENT_DIR/templates/header.tpl" ]]; then
    HEADER_TEMPLATE="$PARENT_DIR/templates/header.tpl"
  fi
fi

# Resolve footer template
if [[ ! -f "$FOOTER_TEMPLATE" ]]; then
  if [[ -n "${RADAR_LOVE_HOME:-}" && -f "$RADAR_LOVE_HOME/templates/footer.tpl" ]]; then
    FOOTER_TEMPLATE="$RADAR_LOVE_HOME/templates/footer.tpl"
  elif command -v brew &>/dev/null && HOMEBREW_PREFIX="$(brew --prefix radar_love_cli 2>/dev/null)" && [[ -f "$HOMEBREW_PREFIX/templates/footer.tpl" ]]; then
    FOOTER_TEMPLATE="$HOMEBREW_PREFIX/templates/footer.tpl"
  elif [[ -f "$PARENT_DIR/templates/footer.tpl" ]]; then
    FOOTER_TEMPLATE="$PARENT_DIR/templates/footer.tpl"
  fi
fi

# Validate template presence (fail fast)
[[ ! -f "$HEADER_TEMPLATE" ]] && { echo "❌ Header template not found: $HEADER_TEMPLATE"; exit 1; }
[[ ! -f "$FOOTER_TEMPLATE" ]] && { echo "❌ Footer template not found: $FOOTER_TEMPLATE"; exit 1; }

# --- Input Validation ---
die() { echo "❌ $1" >&2; exit 1; }
[[ ! -f "$INPUT" ]] && die "Input file $INPUT not found."
command -v jq >/dev/null || die "'jq' is required."

mkdir -p "${OUTDIR}"
: > "${LOGFILE}"

log() { [[ $QUIET -eq 0 ]] && echo -e "$@"; echo -e "$@" >> "${LOGFILE}"; }

# --- Read Leaks, Filter by Scenario ---
if [[ -n "$SCENARIO" ]]; then
  # Handle scenarios with commas (e.g., "aws,github")
  IFS=',' read -ra SCEN_LIST <<< "$SCENARIO"
  LEAKS=""
  for scen in "${SCEN_LIST[@]}"; do
    SCEN_LEAKS=$(jq -c --arg scenario "$scen" '.leaks[] | select((.scenario | ascii_downcase) == ($scenario | ascii_downcase))' "$INPUT")
    [[ -n "$SCEN_LEAKS" ]] && LEAKS+="${SCEN_LEAKS}"$'\n'
  done
else
  LEAKS=$(jq -c '.leaks[]' "$INPUT")
fi

[[ -z "$LEAKS" ]] && die "No leaks found for scenario '$SCENARIO'."

# --- Parse Language ---
IFS=',' read -r -a LANG_ARRAY <<< "$LANGS_TO_GEN"
should_generate() {
  local lang="${1,,}"         # Lowercase
  [[ "${LANGS_TO_GEN,,}" == "all" ]] && return 0
  for sel in "${LANG_ARRAY[@]}"; do
    [[ "${sel,,}" == "$lang" ]] && return 0
  done
  return 1
}

# --- Pick random count within range ---
MIN=$(jq '.output_size_range.min' "$INPUT")
MAX=$(jq '.output_size_range.max' "$INPUT")
COUNT=$(( RANDOM % (MAX - MIN + 1) + MIN ))
LEAKS_TO_USE=$(echo "$LEAKS" | shuf | head -n "$COUNT")
[[ -z "$LEAKS_TO_USE" ]] && die "No leaks selected for chosen filters."

# --- Template substitution (no sed!) ---
template_subst() {
  local tpl
  tpl=$(<"$1")
  tpl=${tpl//\{\{VERSION\}\}/$VERSION}
  tpl=${tpl//\{\{AUTHOR\}\}/$AUTHOR}
  tpl=${tpl//\{\{TIMESTAMP\}\}/$TIMESTAMP}
  tpl=${tpl//\{\{RUNID\}\}/$RUNID}
  tpl=${tpl//\{\{SCENARIO\}\}/$SCENARIO}
  printf "%s\n" "$tpl"
}

# --- Output Files Map ---
declare -A OUTFILES=(
  [bash]="${OUTDIR}/Vault_Radar_trigger.sh"
  [python]="${OUTDIR}/Vault_Radar_trigger.py"
  [node]="${OUTDIR}/Vault_Radar_trigger.js"
  [docker]="${OUTDIR}/Vault_Radar_trigger.Dockerfile"
  [terraform]="${OUTDIR}/Vault_Radar_trigger.tf"
  [md]="${OUTDIR}/Vault_Radar_leaks_report.md"
)

# --- Leak Injection Helpers ---
inject_bash() {
  jq -r '. | "# ["+.category+"]["+.severity+"] "+.label+"\n"+if .category=="secret" then .value
         elif .category=="pii" then "echo \""+.label+": "+.value+"\""
         elif .category=="non_inclusive" then "# "+.value
         else "" end' <<<"$1"
}

inject_python() {
  jq -r '. | "# ["+.category+"]["+.severity+"] "+.label+"\n"+if .category=="secret" then .label+" = \""+.value+"\""
         elif .category=="pii" then "print(\""+.label+": "+.value+"\")"
         elif .category=="non_inclusive" then "# "+.value
         else "" end' <<<"$1"
}

inject_node() {
  jq -r '. | "// ["+.category+"]["+.severity+"] "+.label+"\n"+if .category=="secret" then "const "+(.label|gsub(" "; "_"))+" = \""+.value+"\";"
         elif .category=="pii" then "console.log(\""+.label+": "+.value+"\");"
         elif .category=="non_inclusive" then "// "+.value
         else "" end' <<<"$1"
}

inject_docker() {
  jq -r '. | "# ["+.category+"]["+.severity+"] "+.label+"\n"+if .category=="secret" or .category=="pii" then "ENV "+(.label|gsub(" "; "_"))+"="+.value
         elif .category=="non_inclusive" then "# "+.value
         else "" end' <<<"$1"
}

inject_terraform() {
  jq -r '. | "# ["+.category+"]["+.severity+"] "+.label+"\n"+if .category=="secret" or .category=="pii" then "variable \""+(.label|gsub(" "; "_"))+"\" { default = \""+.value+"\" }"
         elif .category=="non_inclusive" then "# "+.value
         else "" end' <<<"$1"
}

inject_md() {
  local leak_json="$1"
  local language="$2"
  jq -r --arg lang "$language" '
    select(.languages[] | ascii_downcase == $lang)
    | "| " + .category
      + " | " + .label
      + " | " + .value
      + " | " + .severity
      + " | " + $lang
      + " | " + (.author // "")
      + " | " + (.source // "")
      + " | " + (.demo_notes // "")
      + " | " + (.scenario // "")
      + " |"
  ' <<<"$leak_json"
}

# --- Main Output Loop ---
TMP_GEN_FILE="${OUTDIR}/.generated_langs"
: > "${TMP_GEN_FILE}"

declare -A HEADER_DONE

log "# Vault Radar Demo Leak Seed Run: $RUNID ($TIMESTAMP)"
echo "$LEAKS_TO_USE" | while IFS= read -r leak; do
  [[ -z "$leak" ]] && continue
  LANGS=$(jq -r '.languages[]' <<<"$leak" | awk '{print tolower($0)}')
  for lang in "${!OUTFILES[@]}"; do
    if should_generate "$lang" && grep -qw "$lang" <<<"$LANGS"; then
      echo "$lang" >> "${TMP_GEN_FILE}"
      # Only write header once per language
      if [[ ${HEADER_DONE[$lang]:-0} -eq 0 ]]; then
        template_subst "$HEADER_TEMPLATE" > "${OUTFILES[$lang]}"
        # ---- Add language-specific intro just after header ----
        if [[ "$lang" == "bash" ]]; then
          awk -v ver="$VERSION" '
            NR==1 { print; print "#!/usr/bin/env bash\n# shellcheck disable=SC2034\nVERSION=\""ver"\""; next }
            { print }
          ' "${OUTFILES[$lang]}" > "${OUTFILES[$lang]}.tmp" && mv "${OUTFILES[$lang]}.tmp" "${OUTFILES[$lang]}"
        elif [[ "$lang" == "python" ]]; then
          awk -v ver="$VERSION" '
            NR==1 { print; print "#!/usr/bin/env python3\n# VERSION: "ver; next }
            { print }
          ' "${OUTFILES[$lang]}" > "${OUTFILES[$lang]}.tmp" && mv "${OUTFILES[$lang]}.tmp" "${OUTFILES[$lang]}"
        elif [[ "$lang" == "node" ]]; then
          awk -v ver="$VERSION" '
            NR==1 { print; print "// VERSION: "ver; next }
            { print }
          ' "${OUTFILES[$lang]}" > "${OUTFILES[$lang]}.tmp" && mv "${OUTFILES[$lang]}.tmp" "${OUTFILES[$lang]}"
        fi
        HEADER_DONE[$lang]=1
      fi
      case "$lang" in
        bash)     [[ $DRYRUN -eq 0 ]] && inject_bash "$leak" >> "${OUTFILES[$lang]}";;
        python)   [[ $DRYRUN -eq 0 ]] && inject_python "$leak" >> "${OUTFILES[$lang]}";;
        node)     [[ $DRYRUN -eq 0 ]] && inject_node "$leak" >> "${OUTFILES[$lang]}";;
        docker)   [[ $DRYRUN -eq 0 ]] && inject_docker "$leak" >> "${OUTFILES[$lang]}";;
        terraform)[[ $DRYRUN -eq 0 ]] && inject_terraform "$leak" >> "${OUTFILES[$lang]}";;
        md)       [[ $DRYRUN -eq 0 ]] && inject_md "$leak" >> "${OUTFILES[$lang]}";;
      esac
      [[ $DRYRUN -eq 0 ]] && echo "" >> "${OUTFILES[$lang]}"
    fi
  done
done

# --- Deduplicate and collect generated language ---
mapfile -t GEN_LANGS < <(sort -u "${TMP_GEN_FILE}")
rm -f "${TMP_GEN_FILE}"

# --- Add Markdown Table Header ---
if should_generate "md" && [[ $DRYRUN -eq 0 && " ${GEN_LANGS[*]} " =~ " md " ]]; then
  MDH="${OUTFILES[md]}"
  awk 'BEGIN{print "| Category | Label | Value | Severity | Language | Author | Source | Notes | Scenario |\n|---|---|---|---|---|---|---|---|---|"} 1' "$MDH" > "$MDH.tmp" && mv "$MDH.tmp" "$MDH"
fi

# --- Add Footers ---
for lang in "${GEN_LANGS[@]}"; do
  if should_generate "$lang" && [[ $DRYRUN -eq 0 ]]; then
    template_subst "$FOOTER_TEMPLATE" >> "${OUTFILES[$lang]}"
  fi
done

# --- Write Cleanup Script ---
if [[ $DRYRUN -eq 0 ]]; then
  {
    echo '#!/bin/bash'
    echo "echo \"Cleaning up all Vault Radar demo outputs in: ${OUTDIR}\""
    echo "rm -f \"${LOGFILE}\" \"${CLEANUP_SCRIPT}\""
    for lang in "${GEN_LANGS[@]}"; do
      [[ -f "${OUTFILES[$lang]}" ]] && echo "rm -f \"${OUTFILES[$lang]}\""
    done
    echo 'echo "Cleanup complete."'
  } > "${CLEANUP_SCRIPT}"
  chmod +x "${CLEANUP_SCRIPT}"
fi

# --- Run Lint/Sanity Check if Requested ---
if [[ $LINT -eq 1 && $DRYRUN -eq 0 ]]; then
  if [[ -f "sanity_check.sh" ]]; then
    log "Running sanity_check.sh on outputs..."
    ./sanity_check.sh "${OUTDIR}" > "${OUTDIR}/sanity_check_report.md"
    log "Sanity check output: ${OUTDIR}/sanity_check_report.md"
  else
    log "sanity_check.sh not found, skipping lint."
  fi
fi

# --- Output Results ---
if [[ $QUIET -eq 0 ]]; then
  log "✅ Run complete. Generated files:"
  for lang in "${GEN_LANGS[@]}"; do
    file="${OUTFILES[$lang]}"
    sample=$(head -n 8 "$file" | tail -n 1)
    log " - $file (sample: $(echo "$sample" | head -c 60))"
  done
  # For requested language that were not generated (remove file if any was created accidentally)
  for lang in "${!OUTFILES[@]}"; do
    if should_generate "$lang" && [[ ! " ${GEN_LANGS[*]} " =~ " $lang " ]]; then
      log "⚠️  No leaks generated for $lang (missing leaks or scenario?)"
      [[ -f "${OUTFILES[$lang]}" ]] && rm -f "${OUTFILES[$lang]}"
    fi
  done
  [[ $DRYRUN -eq 1 ]] && log "(Dry run: no files written.)"
  log "To cleanup: ${CLEANUP_SCRIPT}"
fi
