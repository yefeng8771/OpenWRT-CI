#!/bin/bash
# wifi-band-ssid.sh — WiFi SSID 按频段区分
# 覆盖上游的统一 SSID 设置

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"
WRT_SSID="${WRT_SSID:-QWRT}"

echo "[wifi-ssid] Applying band-specific SSID..."

WIFI_UC="$WORKSPACE/$WRT_DIR/package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_UC" ]; then
    # 将统一 SSID 替换为按频段区分的 SSID
    # 2g -> QWRT4, 5g -> QWRT5, 6g -> QWRT6
    SSID_BASE="${WRT_SSID}"
    if grep -q "ssid='\$WRT_SSID'" "$WIFI_UC" 2>/dev/null || grep -q "ssid='ImmortalWRT'" "$WIFI_UC" 2>/dev/null; then
        sed -i "s/ssid='.*'/ssid='$(echo $SSID_BASE | sed 's/[&/\]/\\&/g')'/g" "$WIFI_UC"
        # 如果上游已经用统一 SSID，改为按频段
        sed -i "s/ssid='$SSID_BASE'/ssid=(band_name == \"2g\" ? \"${SSID_BASE}4\" : band_name == \"5g\" ? \"${SSID_BASE}5\" : \"${SSID_BASE}6\")/g" "$WIFI_UC"
        echo "[wifi-ssid] Applied band-specific SSID: ${SSID_BASE}4/${SSID_BASE}5/${SSID_BASE}6"
    fi
fi

# 同时需要确保 Settings.sh 中的 WiFi 逻辑与此一致
# Settings.sh 中的 WiFi 修改也应在 patch 中覆盖
SETTINGS_SH="$WORKSPACE/Scripts/Settings.sh"
if [ -f "$SETTINGS_SH" ]; then
    # 替换 Settings.sh 中的统一 SSID 为按频段 SSID
    if grep -q "ssid='\$WRT_SSID'" "$SETTINGS_SH"; then
        sed -i "s|sed -i \"s/ssid='.*'/ssid='\$WRT_SSID'/g\" \$WIFI_UC|sed -i 's/\"ImmortalWRT\"/(band_name == \"2g\" ? \"\${WRT_SSID}4\" : band_name == \"5g\" ? \"\${WRT_SSID}5\" : \"\${WRT_SSID}6\")/g' \$WIFI_UC|" "$SETTINGS_SH"
        echo "[wifi-ssid] Updated Settings.sh WiFi SSID logic"
    fi
fi

echo "[wifi-ssid] Done"
