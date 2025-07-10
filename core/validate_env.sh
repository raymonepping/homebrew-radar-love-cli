#!/usr/bin/env bash
set -euo pipefail

VERSION="2.8.2"

INSTALL_MISSING=false
AUTO_CONFIRM=false

# ----------------------------
# 🧾 Parse CLI flags
# ----------------------------
for arg in "$@"; do
  case "$arg" in
    --install-missing) INSTALL_MISSING=true ;;
    --yes) AUTO_CONFIRM=true ;;
    --help)
      echo "Usage: $0 [--install-missing] [--yes]"
      echo "  --install-missing   Prompt to install any missing tools"
      echo "  --yes               Auto-confirm install prompts (non-interactive)"
      exit 0
      ;;
  esac
done

REQUIRED_TOOLS=(gh jq awk sed shfmt shellcheck git shuf)

echo -e "\n📋 Running vault_radar_validator.sh v${VERSION}"
echo "🧪 Checking tools: ${REQUIRED_TOOLS[*]}"
echo -e "\n==== 🔍 Validating Environment Dependencies ====\n"

all_passed=true

read_confirm() {
  local tool="$1"
  if [[ "$AUTO_CONFIRM" == true ]]; then return 0; fi
  echo -n "📦 Do you want to install ${tool}? [y/N]: "
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

for tool in "${REQUIRED_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf "🛠️ %-12s found\n" "$tool"
    continue
  fi

  # macOS fallback: shuf → gshuf (from coreutils)
  if [[ "$tool" == "shuf" && "$(uname -s)" == "Darwin" ]]; then
    if command -v gshuf >/dev/null 2>&1; then
      # Symlink if not present (needs sudo for /opt/homebrew/bin)
      sudo ln -sf "$(command -v gshuf)" /opt/homebrew/bin/shuf
      printf "🔁 %-12s gshuf symlinked → shuf\n" "$tool"
      continue
    fi
  fi

  printf "❌ %-12s missing\n" "$tool"
  all_passed=false

  if [[ "$INSTALL_MISSING" == true ]]; then
    if ! read_confirm "$tool"; then
      echo "⏭️  Skipping install for: $tool"
      continue
    fi

    case "$(uname -s)" in
      Darwin)
        if [[ "$tool" == "shuf" ]]; then
          echo "📦 Installing coreutils via Homebrew (for gshuf/shuf)..."
          brew install coreutils || echo "⚠️ Failed to install coreutils"
          if command -v gshuf >/dev/null 2>&1; then
            sudo ln -sf "$(command -v gshuf)" /opt/homebrew/bin/shuf
            printf "🔁 %-12s gshuf symlinked → shuf\n" "$tool"
          fi
        else
          echo "📦 Installing $tool via Homebrew..."
          brew install "$tool" || echo "⚠️ Failed to install $tool"
        fi
        ;;
      Linux)
        echo "📦 Installing $tool via APT..."
        sudo apt-get update -y && sudo apt-get install -y "$tool" || echo "⚠️ Failed to install $tool"
        ;;
      *)
        echo "❌ Unsupported OS for automatic install."
        ;;
    esac
  fi
done

echo ""

if [[ "$all_passed" == true ]]; then
  echo "✅ All dependencies satisfied."
  exit 0
else
  echo -e "\n⚠️  One or more required tools are missing or failed to install."
  exit 1
fi
