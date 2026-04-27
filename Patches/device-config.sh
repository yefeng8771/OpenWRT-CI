#!/bin/bash
# device-config.sh — 收敛 IPQ60XX-WIFI 设备到只有 jdcloud_re-cs-02
#
# QCA-6.12-VIKINGYFY.yml 已不再走 CI（QWRT.yml 接管），其矩阵不需要改。
# 我们只需要在 IPQ60XX-WIFI.txt 配置文件里把其它设备关掉，留 jdcloud_re-cs-02 唯一启用。
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "[device] Restricting IPQ60XX-WIFI to jdcloud_re-cs-02 only..."

CONFIG_FILE="$WORKSPACE/Config/IPQ60XX-WIFI.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[device] WARNING: $CONFIG_FILE not found, skipping"
    exit 0
fi

# 1) 把所有 ipq60xx 设备先关掉
sed -i 's/^CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_\(.*\)=y/CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_\1=n/' "$CONFIG_FILE"
# 2) 单独把 jdcloud_re-cs-02 打开
sed -i 's/CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02=n/CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02=y/' "$CONFIG_FILE"

echo "[device] Done"
