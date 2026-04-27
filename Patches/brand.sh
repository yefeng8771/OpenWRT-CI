#!/bin/bash
# brand.sh — 品牌定制补丁
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
export WRT_NAME='QWRT'
export WRT_SSID='QWRT'
export WRT_WORD='12345678'
export WRT_THEME='argon'
export WRT_IP='172.16.3.1'
echo "[brand] Applying brand customization..."
DIY_SH="$WORKSPACE/diy.sh"
if [ -f "$DIY_SH" ]; then
    sed -i "s/^export WRT_NAME=.*/export WRT_NAME='$WRT_NAME'/" "$DIY_SH"
    sed -i "s/^export WRT_SSID=.*/export WRT_SSID='$WRT_SSID'/" "$DIY_SH"
    sed -i "s/^export WRT_WORD=.*/export WRT_WORD='$WRT_WORD'/" "$DIY_SH"
    sed -i "s/^export WRT_THEME=.*/export WRT_THEME='$WRT_THEME'/" "$DIY_SH"
    sed -i "s/^export WRT_IP=.*/export WRT_IP='$WRT_IP'/" "$DIY_SH"
    sed -i "s/export WRT_CONFIG="IPQ60XX-NOWIFI"/export WRT_CONFIG="IPQ60XX-WIFI"/" "$DIY_SH"
    echo "[brand] diy.sh updated"
fi
QCA_YML="$WORKSPACE/.github/workflows/QCA-6.12-VIKINGYFY.yml"
if [ -f "$QCA_YML" ]; then
    sed -i "s/WRT_THEME: .*/WRT_THEME: $WRT_THEME/" "$QCA_YML"
    sed -i "s/WRT_NAME: .*/WRT_NAME: $WRT_NAME/" "$QCA_YML"
    sed -i "s/WRT_SSID: .*/WRT_SSID: $WRT_SSID/" "$QCA_YML"
    sed -i "s/WRT_WORD: .*/WRT_WORD: $WRT_WORD/" "$QCA_YML"
    sed -i "s/WRT_IP: .*/WRT_IP: $WRT_IP/" "$QCA_YML"
    echo "[brand] QCA workflow updated"
fi
echo "[brand] Done"
