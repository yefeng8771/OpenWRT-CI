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
		mv -f "$REPO_NAME" "$PKG_NAME"
	fi
}

UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"

echo "[packages] Minimal package sync done"
