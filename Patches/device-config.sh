#!/bin/bash
# device-config.sh — 设备选择覆盖
# 将 IPQ60XX-WIFI 配置精简为仅京东云亚瑟

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "[device] Applying device selection..."

CONFIG_FILE="$WORKSPACE/Config/IPQ60XX-WIFI.txt"
if [ -f "$CONFIG_FILE" ]; then
    # 禁用所有设备
    sed -i 's/^CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_\(.*\)=y/CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_\1=n/' "$CONFIG_FILE"
    # 启用京东云亚瑟
    sed -i 's/CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02=n/CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02=y/' "$CONFIG_FILE"
    echo "[device] IPQ60XX-WIFI.txt: only jdcloud_re-cs-02 enabled"
fi

# 编译矩阵精简：只保留 IPQ60XX-WIFI
QCA_YML="$WORKSPACE/.github/workflows/QCA-6.12-VIKINGYFY.yml"
if [ -f "$QCA_YML" ]; then
    sed -i 's/CONFIG: \[IPQ60XX-NOWIFI, IPQ60XX-WIFI\]/CONFIG: [IPQ60XX-WIFI]/' "$QCA_YML"
    echo "[device] QCA workflow matrix: only IPQ60XX-WIFI"
fi

echo "[device] Done"
