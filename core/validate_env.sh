#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
REQUIRED_TOOLS=(gh jq awk sed shfmt shellcheck git)

echo "==== 🔍 Validating Environment Dependencies ===="

all_passed=true

for tool in "${REQUIRED_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "🛠️ - Found: $tool"
  else
    echo "❌ - Missing: $tool"
    all_passed=false
  fi
done

if [ "$all_passed" = true ]; then
  echo "✅ - All dependencies satisfied."
else
  echo "⚠️  One or more required tools are missing. Please install them."
  exit 1
fi
