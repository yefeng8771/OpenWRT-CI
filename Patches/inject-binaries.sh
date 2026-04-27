#!/bin/bash
# inject-binaries.sh — 下载并注入预编译二进制文件
# 从 WRT-CORE.yml 中抽取，使其独立维护
#
# 用法: bash inject-binaries.sh [WORK_DIR]
#   WORK_DIR: wrt 构建目录（默认 ./wrt）

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WORK_DIR="${1:-$WORKSPACE/wrt}"

echo "[inject] Injecting prebuilt binaries into $WORK_DIR..."

cd "$WORK_DIR"

mkdir -p ./files
# 复制自定义 files 目录
if [ -d "$WORKSPACE/files" ]; then
    cp -a "$WORKSPACE/files/." ./files/
fi
mkdir -p ./files/usr/bin ./files/etc/init.d ./files/etc/mosdns

# ============ 架构检测 ============
OWRT_ARCH=$(grep -m 1 '^CONFIG_TARGET_ARCH_PACKAGES=' .config | cut -d'=' -f2 | tr -d "\"")
case "$OWRT_ARCH" in
    aarch64*|arm64*)
        RELEASE_ARCH=arm64
        ;;
    x86_64|amd64*)
        RELEASE_ARCH=amd64
        ;;
    *)
        echo "[inject] Unsupported arch: $OWRT_ARCH"
        exit 1
        ;;
esac
echo "[inject] Target arch: $OWRT_ARCH -> $RELEASE_ARCH"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# ============ sing-box: reF1nd prerelease ============
echo "[inject] Downloading sing-box prerelease for $RELEASE_ARCH..."

SINGBOX_API="https://api.github.com/repos/reF1nd/sing-box-releases/releases"
SINGBOX_URL=$(curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN:-}" \
    -H 'Accept: application/vnd.github+json' \
    "$SINGBOX_API" | jq -r --arg arch "$RELEASE_ARCH" '
        [ .[]
            | select(.draft == false and .prerelease == true)
            | .assets[]?
            | select(.name | endswith("-linux-" + $arch + "-musl.tar.gz"))
            | .browser_download_url
        ][0]
    ')

if [ -n "$SINGBOX_URL" ] && [ "$SINGBOX_URL" != "null" ]; then
    SINGBOX_ASSET=$(basename "$SINGBOX_URL")
    curl -fL "$SINGBOX_URL" -o "$TMP_DIR/$SINGBOX_ASSET"
    tar -xzf "$TMP_DIR/$SINGBOX_ASSET" -C "$TMP_DIR"
    SINGBOX_BIN=$(find "$TMP_DIR" -type f -name sing-box | head -n 1)
    if [ -n "$SINGBOX_BIN" ] && [ -f "$SINGBOX_BIN" ]; then
        install -m 0755 "$SINGBOX_BIN" ./files/usr/bin/sing-box
        echo "[inject] sing-box injected: $SINGBOX_ASSET"
    else
        echo "[inject] WARNING: sing-box binary not found in archive"
    fi
else
    echo "[inject] WARNING: sing-box prerelease not found for $RELEASE_ARCH"
fi

# ============ mosdns: yyysuo 预编译 ============
echo "[inject] Downloading mosdns binary for $RELEASE_ARCH..."

MOSDNS_API="https://api.github.com/repos/yyysuo/mosdns/releases/latest"
MOSDNS_URL=$(curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN:-}" \
    -H 'Accept: application/vnd.github+json' \
    "$MOSDNS_API" | jq -r --arg arch "$RELEASE_ARCH" '
        .assets[]?
        | select(.name == ("mosdns-linux-" + $arch + ".zip"))
        | .browser_download_url
    ' | head -n 1)

if [ -n "$MOSDNS_URL" ] && [ "$MOSDNS_URL" != "null" ]; then
    MOSDNS_ASSET=$(basename "$MOSDNS_URL")
    curl -fL "$MOSDNS_URL" -o "$TMP_DIR/$MOSDNS_ASSET"
    unzip -q "$TMP_DIR/$MOSDNS_ASSET" -d "$TMP_DIR/mosdns-bin"
    MOSDNS_BIN=$(find "$TMP_DIR/mosdns-bin" -type f -name mosdns | head -n 1)
    if [ -n "$MOSDNS_BIN" ] && [ -f "$MOSDNS_BIN" ]; then
        install -m 0755 "$MOSDNS_BIN" ./files/usr/bin/mosdns
        echo "[inject] mosdns binary injected: $MOSDNS_ASSET"
    else
        echo "[inject] WARNING: mosdns binary not found in archive"
    fi
else
    echo "[inject] WARNING: mosdns release not found for $RELEASE_ARCH"
fi

# ============ mosdns 配置 ============
echo "[inject] Downloading mosdns config..."

MOSDNS_CFG_URL="https://raw.githubusercontent.com/yyysuo/firetv/refs/heads/master/mosdnsconfigupdate/mosdns1225all.zip"
curl -fL "$MOSDNS_CFG_URL" -o "$TMP_DIR/mosdns-config.zip"
find ./files/etc/mosdns -mindepth 1 -maxdepth 1 -exec rm -rf {} +
unzip -q -o "$TMP_DIR/mosdns-config.zip" -d ./files/etc/mosdns
echo "[inject] mosdns config extracted"

# ============ mosdns init 脚本 ============
echo "[inject] Downloading mosdns init script..."

curl -fsSL "https://raw.githubusercontent.com/yyysuo/mosdns/main/scripts/openwrt/mosdns-init-openwrt" -o "$TMP_DIR/mosdns.init"
# 修改 CONF 路径为 config_custom.yaml
sed -i 's#^CONF=\./config\.yaml#CONF=./config_custom.yaml#' "$TMP_DIR/mosdns.init"
install -m 0755 "$TMP_DIR/mosdns.init" ./files/etc/init.d/mosdns
echo "[inject] mosdns init script installed"

# ============ 验证 ============
echo "[inject] Verification:"
file ./files/usr/bin/sing-box ./files/usr/bin/mosdns 2>/dev/null || true
ls -la ./files/usr/bin/ ./files/etc/init.d/mosdns 2>/dev/null || true

echo "[inject] Done"
