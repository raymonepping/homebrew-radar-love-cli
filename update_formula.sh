#!/usr/bin/env bash
set -euo pipefail

# Fetch latest tag
TAG=$(git describe --tags --abbrev=0)
TAR_URL="https://github.com/raymonepping/radar_love_cli/archive/refs/tags/${TAG}.tar.gz"

# Get SHA256
curl -Ls "$TAR_URL" -o temp.tar.gz
SHA=$(shasum -a 256 temp.tar.gz | awk '{print $1}')
rm temp.tar.gz

# Update formula
sed -i '' "s|url .*|url      \"$TAR_URL\"|" radar_love_cli.rb
sed -i '' "s|sha256 .*|sha256   \"$SHA\"|" radar_love_cli.rb
sed -i '' "s|version .*|version  \"${TAG#v}\"|" radar_love_cli.rb

echo "✅ radar_love_cli.rb updated to $TAG with new SHA: $SHA"
