#!/bin/bash
# package-filter.sh — 增强 WRT_PACKAGE 输入验证
# 在上游的 Settings.sh 基础上增加更严格的格式过滤

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "[package-filter] Enhancing WRT_PACKAGE input validation..."

SETTINGS_SH="$WORKSPACE/Scripts/Settings.sh"
if [ -f "$SETTINGS_SH" ]; then
    # 替换简单的 echo 为带过滤的版本
    # 上游: echo -e "$WRT_PACKAGE" >> ./.config
    # 修改为: 过滤空行和非法格式
    if grep -q 'echo -e "\$WRT_PACKAGE" >> ./.config$' "$SETTINGS_SH"; then
        sed -i 's|echo -e "\$WRT_PACKAGE" >> ./.config|echo -e "$WRT_PACKAGE" \\n\t\t| sed '\''/^[[:space:]]*$/d'\'' \\n\t\t| grep -E '\''^(CONFIG_[A-Z0-9_]+=.*|# CONFIG_[A-Z0-9_]+ is not set|#.*)\$'\'' >> ./.config || true|' "$SETTINGS_SH"
        echo "[package-filter] Settings.sh patched"
    elif grep -q 'echo -e.*WRT_PACKAGE.*>>.*\.config' "$SETTINGS_SH"; then
        echo "[package-filter] Settings.sh already has custom filtering, skipping"
    fi
fi

echo "[package-filter] Done"
