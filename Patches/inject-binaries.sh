#!/bin/bash
# inject-binaries.sh — 下载并注入预编译二进制到 wrt/files/
#
# 当前仅注入：
#   /usr/bin/sing-box  ← reF1nd/sing-box-releases prerelease (linux-<arch>-musl)
#
# easytier 不走注入流程，保持上游构建方式，只通过 patches.d/easytier-pre.sh
# 把 version.mk 更新到最新 prerelease。
#
# 用法: bash inject-binaries.sh [WORK_DIR]
#   WORK_DIR: wrt 构建目录（默认 ./wrt）

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WORK_DIR="${1:-$WORKSPACE/wrt}"

echo "[inject] Injecting prebuilt binaries into $WORK_DIR..."
cd "$WORK_DIR"

# 1) 先把仓库 files/ 目录整体合入（包含 sing-box init/config/nft、uci-defaults）
mkdir -p ./files
if [ -d "$WORKSPACE/files" ]; then
    cp -a "$WORKSPACE/files/." ./files/
    echo "[inject] Merged custom files/ from repo"
fi
mkdir -p ./files/usr/bin ./files/etc/init.d

# 2) 架构检测：覆盖常见 OpenWrt CONFIG_TARGET_ARCH_PACKAGES 取值
OWRT_ARCH=$(grep -m 1 '^CONFIG_TARGET_ARCH_PACKAGES=' .config | cut -d'=' -f2 | tr -d '"')
case "$OWRT_ARCH" in
    aarch64*|arm64*)        RELEASE_ARCH=arm64 ;;
    x86_64|amd64*)          RELEASE_ARCH=amd64 ;;
    arm_cortex-a7*|armv7*)  RELEASE_ARCH=armv7 ;;
    arm_cortex-a9*)         RELEASE_ARCH=armv7 ;;
    arm_cortex-a5*)         RELEASE_ARCH=armv5 ;;
    mipsel*)                RELEASE_ARCH=mipsle ;;
    mips_24kc*|mips*)       RELEASE_ARCH=mips ;;
    *)
        echo "[inject] ERROR: Unsupported arch: $OWRT_ARCH"
        exit 1
        ;;
esac

echo "[inject] Target arch: $OWRT_ARCH -> $RELEASE_ARCH"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# 公共 curl 鉴权头：避免匿名访问 60 次/h 限速
GH_HEADERS=(-H 'Accept: application/vnd.github+json')
if [ -n "${GITHUB_TOKEN:-}" ]; then
    GH_HEADERS+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

# ============ sing-box: reF1nd prerelease ============
echo "[inject] Downloading sing-box prerelease for $RELEASE_ARCH..."

SINGBOX_URL=$(curl -fsSL "${GH_HEADERS[@]}" \
    "https://api.github.com/repos/reF1nd/sing-box-releases/releases" \
    | jq -r --arg arch "$RELEASE_ARCH" '
        [ .[]
            | select(.draft == false and .prerelease == true)
            | .assets[]?
            | select(.name | endswith("-linux-" + $arch + "-musl.tar.gz"))
            | .browser_download_url
        ][0]')

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

# ============ 验证 ============
echo "[inject] Verification:"
[ -f ./files/usr/bin/sing-box ] && file ./files/usr/bin/sing-box
[ -f ./files/etc/init.d/sing-box ] && echo "init.d/sing-box: present (from repo files/)"
[ -f ./files/etc/sing-box/config.json ] && echo "sing-box/config.json: present (from repo files/)"
[ -f ./files/etc/nftables.d/40-singbox-tproxy.nft ] && echo "nftables.d/40-singbox-tproxy.nft: present"
[ -f ./files/etc/uci-defaults/99-qwrt-defaults ] && echo "uci-defaults/99-qwrt-defaults: present"

echo "[inject] Done"
