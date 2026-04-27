#!/bin/bash
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"
echo "[fantastic-feed] Adding fantastic-packages feed..."
FEEDS_CONF="$WORKSPACE/$WRT_DIR/feeds.conf.default"
if [ -f "$FEEDS_CONF" ]; then
    if ! grep -q "fantastic_packages" "$FEEDS_CONF"; then
        echo "src-git --root=feeds fantastic_packages https://github.com/fantastic-packages/packages.git;master" >> "$FEEDS_CONF"
        echo "[fantastic-feed] Added to feeds.conf.default"
    fi
fi
echo "[fantastic-feed] Done"
