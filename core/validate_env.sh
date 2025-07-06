#!/usr/bin/env bash
set -euo pipefail

VERSION="1.2.1"

REQUIRED_TOOLS=(gh jq awk sed shfmt shellcheck git)

echo -e "\n==== 🔍 Validating Environment Dependencies ====\n"

all_passed=true

for tool in "${REQUIRED_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "🛠️  Found: $tool"
  else
    echo "❌ Missing: $tool"
    all_passed=false
  fi
done

echo ""

if [[ "$all_passed" == true ]]; then
  echo "✅ All dependencies satisfied."
  exit 0
else
  echo -e "\n⚠️  One or more required tools are missing. Please install them."
  exit 1
fi
