#!/bin/bash
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"
WRT_SSID="${WRT_SSID:-QWRT}"
echo "[wifi-ssid] Applying band-specific SSID..."
SETTINGS_SH="$WORKSPACE/Scripts/Settings.sh"
WIFI_UC="$WORKSPACE/$WRT_DIR/package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_UC" ]; then
    sed -i "s/ssid='.*'/ssid='$(echo $WRT_SSID)'/g" "$WIFI_UC"
    sed -i "s/ssid='$WRT_SSID'/ssid=(band_name == \"2g\" ? \"${WRT_SSID}4\" : band_name == \"5g\" ? \"${WRT_SSID}5\" : \"${WRT_SSID}6\")/g" "$WIFI_UC"
    echo "[wifi-ssid] Applied band-specific SSID"
fi
echo "[wifi-ssid] Done"
