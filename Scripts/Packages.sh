#!/bin/bash
set -euo pipefail

# 仅同步当前 QWRT 主线真正需要的外部包，避免先拉一堆、后面再删一堆。
# 当前保留：
#   - luci-theme-argon
#   - luci-app-easytier

UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=${4:-}
	local PKG_LIST=("$PKG_NAME" ${5:-})
	local REPO_NAME=${PKG_REPO#*/}

	echo "[packages] Syncing $PKG_NAME from $PKG_REPO@$PKG_BRANCH"

	for NAME in "${PKG_LIST[@]}"; do
		[ -z "$NAME" ] && continue
		find ../feeds/luci/ ../feeds/packages/ . -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null | while read -r DIR; do
			rm -rf "$DIR"
			echo "[packages] Removed existing: $DIR"
		done
	done

	git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git"

	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find "./$REPO_NAME"/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
		rm -rf "./$REPO_NAME/"
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		if [[ "$REPO_NAME" != "$PKG_NAME" ]]; then
			mv -f "$REPO_NAME" "$PKG_NAME"
		fi
	fi
}

UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"

# Syncthing: keep core package aligned with OpenWrt 24.10 to avoid master-only Go/package changes.
UPDATE_PACKAGE "syncthing" "openwrt/packages" "openwrt-24.10" "pkg"
if [ -f "syncthing/Makefile" ]; then
	python3 - <<'PY'
from pathlib import Path
p = Path('syncthing/Makefile')
text = p.read_text()
old = 'include ../../lang/golang/golang-package.mk'
new = 'include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk'
if old in text:
    p.write_text(text.replace(old, new, 1))
    print('[packages] Patched syncthing golang include path')
else:
    print('[packages] syncthing golang include path already patched or not found')
PY
fi
UPDATE_PACKAGE "luci-app-syncthing" "danchexiaoyang/luci-app-syncthing" "main" "name"

# 删除明确不需要的官方/第三方插件，避免被 feeds 或上游重新带入。
rm -rf ../feeds/luci/applications/luci-app-{passwall*,mosdns,dockerman,dae*,daed*,nikki,zerotier,tailscale,bypass*} 2>/dev/null || true
rm -rf ../feeds/packages/net/{v2ray-geodata,dae*,daed*,mosdns,nikki,zerotier,tailscale} 2>/dev/null || true

echo "[packages] Minimal package sync done"
