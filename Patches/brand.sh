#!/bin/bash
# brand.sh — 品牌定制补丁
# 覆盖上游的 DAE-WRT/OWRT 品牌参数为 QWRT
# 所有品牌相关参数集中在此文件管理，同步上游后只需重新运行此脚本

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"

# ============ 品牌参数（只改这里） ============
export WRT_NAME='QWRT'
export WRT_SSID='QWRT'
export WRT_WORD='12345678'
export WRT_THEME='argon'
export WRT_IP='172.16.3.1'
# ============================================

echo "[brand] Applying brand customization..."

# 1. 修改 diy.sh 中的品牌参数
DIY_SH="$WORKSPACE/diy.sh"
if [ -f "$DIY_SH" ]; then
    sed -i "s/^export WRT_NAME=.*/export WRT_NAME='$WRT_NAME'/" "$DIY_SH"
    sed -i "s/^export WRT_SSID=.*/export WRT_SSID='$WRT_SSID'/" "$DIY_SH"
    sed -i "s/^export WRT_WORD=.*/export WRT_WORD='$WRT_WORD'/" "$DIY_SH"
    sed -i "s/^export WRT_THEME=.*/export WRT_THEME='$WRT_THEME'/" "$DIY_SH"
    sed -i "s/^export WRT_IP=.*/export WRT_IP='$WRT_IP'/" "$DIY_SH"
    # 默认配置改为 WIFI 版本
    sed -i "s/export WRT_CONFIG=\"IPQ60XX-NOWIFI\"/export WRT_CONFIG=\"IPQ60XX-WIFI\"/" "$DIY_SH"
    echo "[brand] diy.sh updated"
fi

# 2. 修改 QCA workflow 中的品牌参数
QCA_YML="$WORKSPACE/.github/workflows/QCA-6.12-VIKINGYFY.yml"
if [ -f "$QCA_YML" ]; then
    sed -i "s/WRT_THEME: .*/WRT_THEME: $WRT_THEME/" "$QCA_YML"
    sed -i "s/WRT_NAME: .*/WRT_NAME: $WRT_NAME/" "$QCA_YML"
    sed -i "s/WRT_SSID: .*/WRT_SSID: $WRT_SSID/" "$QCA_YML"
    sed -i "s/WRT_WORD: .*/WRT_WORD: $WRT_WORD/" "$QCA_YML"
    sed -i "s/WRT_IP: .*/WRT_IP: $WRT_IP/" "$QCA_YML"
    echo "[brand] QCA-6.12-VIKINGYFY.yml updated"
fi

echo "[brand] Done. Brand: $WRT_NAME, SSID: $WRT_SSID, IP: $WRT_IP, Theme: $WRT_THEME"
