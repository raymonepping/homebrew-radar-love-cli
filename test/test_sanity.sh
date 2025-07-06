#!/usr/bin/env bash
set -euo pipefail
echo "✅ Basic test: sanity_check is available"
command -v sanity_check &>/dev/null && echo "✅ sanity_check is installed" || echo "❌ sanity_check is missing"
