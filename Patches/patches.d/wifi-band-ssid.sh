#!/bin/bash
# wifi-band-ssid.sh — 按频段区分 SSID 后缀（QWRT4 / QWRT5 / QWRT6）
#
# 上游 mac80211.uc 里通常长这样：
#   ssid='OpenWrt'
# 或 ImmortalWrt 改成：
#   ssid='ImmortalWrt'
# 我们直接把 ssid='...' 整体改成一个三元 ucode 表达式，
# 比之前两条链式 sed（先改成固定值再改成三元）更鲁棒。
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"
WRT_SSID="${WRT_SSID:-QWRT}"

echo "[wifi-ssid] Applying band-specific SSID..."
WIFI_UC="$WORKSPACE/$WRT_DIR/package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"

if [ -f "$WIFI_UC" ]; then
    # 单条 sed：直接把 ssid='...' 替换成三元表达式
    # 注意 mac80211.uc 是 ucode（JS 子集），ssid 字段后接的是表达式
    REPL="ssid=(band_name == \"2g\" ? \"${WRT_SSID}4\" : band_name == \"5g\" ? \"${WRT_SSID}5\" : \"${WRT_SSID}6\")"
    sed -i -E "s|ssid='[^']*'|${REPL}|g" "$WIFI_UC"
    echo "[wifi-ssid] Applied: 2g→${WRT_SSID}4, 5g→${WRT_SSID}5, 6g→${WRT_SSID}6"
else
    echo "[wifi-ssid] WARNING: $WIFI_UC not found, skipping"
fi

echo "[wifi-ssid] Done"
