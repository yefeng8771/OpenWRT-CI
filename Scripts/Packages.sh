#!/bin/bash
. $(dirname "$(realpath "$0")")/function.sh

UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local REPO_URL=$2
	local BRANCH_NAME=$3
	local LOCAL_NAME=$4
	local PKG_SUBNAME=$5
	local PKG_URL="https://github.com/$REPO_URL"
	local REPO_NAME=$(echo $REPO_URL | awk -F '/' '{print $(NF)}')
	local TMP_DIR=$(mktemp -d)
	local PKG_LIST=$(echo $PKG_SUBNAME | tr ' ' '\n')

	if [[ ! $PKG_URL =~ ^https://github.com/ ]]; then
		echo "Unsupported URL: $PKG_URL"
		return 1
	fi

	echo -e "\nDownloading package [$PKG_NAME] from [$PKG_URL] branch [$BRANCH_NAME]"
	git clone --depth 1 -b $BRANCH_NAME $PKG_URL $TMP_DIR/$REPO_NAME
	if [ $? -ne 0 ]; then
		echo "Failed to clone repository: $PKG_URL"
		rm -rf $TMP_DIR
		return 1
	fi

	cd $TMP_DIR/$REPO_NAME || return 1

	for DIR in $(find . -maxdepth 3 -type d); do
		if [ -f "$DIR/Makefile" ] && grep -q "$(PKG_NAME)" "$DIR/Makefile"; then
			if [ -n "$LOCAL_NAME" ]; then
				mv "$DIR" "./$LOCAL_NAME"
				DIR="./$LOCAL_NAME"
			fi
			cp -rf "$DIR" "$GITHUB_WORKSPACE/$WRT_DIR/package/"
			echo "Package [$PKG_NAME] copied from [$DIR]"
			break
		fi
	done

	if [ -n "$PKG_SUBNAME" ]; then
		for NAME in $PKG_LIST; do
			find . -maxdepth 3 -type d -iname "*$NAME*" -exec cp -rf {} "$GITHUB_WORKSPACE/$WRT_DIR/package/" \;
		done
	fi

	rm -rf $TMP_DIR
}

REMOVE_PACKAGE() {
	for PKG_NAME in "$@"; do
		find ./ ../feeds/packages/ ../feeds/luci/ -maxdepth 3 -type d -iname "*$PKG_NAME*" | while read -r PKG_DIR; do
			rm -rf "$PKG_DIR"
		done
		find ./ ../feeds/packages/ ../feeds/luci/ -maxdepth 3 -type f -iname "*$PKG_NAME*.mk" | while read -r PKG_FILE; do
			rm -rf "$PKG_FILE"
		done
		echo "Package [$PKG_NAME] removed"
	done
}

# UPDATE_PACKAGE "OpenAppFilter" "destan19/OpenAppFilter" "master" "" "custom_name1 custom_name2"
# UPDATE_PACKAGE "open-app-filter" "destan19/OpenAppFilter" "master" "" "luci-app-appfilter oaf" 这样会把原有的open-app-filter，luci-app-appfilter，oaf相关组件删除，不会出现coremark错误。
# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "master"
UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "master"

UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"
UPDATE_PACKAGE "diskman" "lisaac/luci-app-diskman" "master"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
UPDATE_PACKAGE "luci-app-tinyfilemanager" "muink/luci-app-tinyfilemanager" "master"
UPDATE_PACKAGE "luci-app-natmapt" "muink/luci-app-natmapt" "master"
UPDATE_PACKAGE "fancontrol" "rockjake/luci-app-fancontrol" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
#UPDATE_PACKAGE "netspeedtest" "sirpdboy/luci-app-netspeedtest" "master" "" "homebox speedtest"
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "luci-app-timewol luci-app-wolplus"


UPDATE_PACKAGE "luci-app-daed" "QiuSimons/luci-app-daed" "master"
UPDATE_PACKAGE "luci-app-pushbot" "zzsj0928/luci-app-pushbot" "master"
#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./ ../feeds/packages/ "$GITHUB_WORKSPACE/package" -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

UPDATE_VERSION_BY_API() {
	local PKG_NAME=$1
	local API_URL=$2
	local ASSET_TEMPLATE=$3
	local MODE=${4:-stable}
	local PKG_FILES=$(find ./ ../feeds/packages/ "$GITHUB_WORKSPACE/package" -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME custom version update has started!"

	local PKG_TAG
	if [ "$MODE" = "prerelease" ]; then
		PKG_TAG=$(GET_LATEST_PRERELEASE_TAG "$API_URL")
	else
		PKG_TAG=$(curl -sL "$API_URL" | jq -r 'if type == "array" then .[0].tag_name else .tag_name end')
	fi
	if [ -z "$PKG_TAG" ] || [ "$PKG_TAG" = "null" ]; then
		echo "$PKG_NAME failed to fetch release tag from API!"
		return
	fi

	for PKG_FILE in $PKG_FILES; do
		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")
		local NEW_SOURCE_VER=$(echo "$PKG_TAG" | sed 's/^v//')
		local NEW_VER=$(printf '%s' "$NEW_SOURCE_VER" | tr 'A-Z' 'a-z')
		local NEW_URL=$(printf '%s' "$ASSET_TEMPLATE" | \
			sed "s#\$(PKG_VERSION)#$NEW_VER#g; s#\$(PKG_SOURCE_VERSION)#$NEW_SOURCE_VER#g; s#\$(PKG_TAG)#$PKG_TAG#g; s#\$(PKG_NAME)#$PKG_NAME#g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"
		echo "download url: $NEW_URL"

		if [ "$MODE" = "force" ] || [ "$OLD_VER" != "$NEW_VER" ]; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			if grep -q '^PKG_SOURCE_VERSION:=' "$PKG_FILE"; then
				sed -i "s/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=$NEW_SOURCE_VER/g" "$PKG_FILE"
			fi
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
#UPDATE_VERSION "tailscale"
UPDATE_VERSION_BY_API "easytier" "https://api.github.com/repos/EasyTier/EasyTier/releases" "https://github.com/EasyTier/EasyTier/releases/download/v\$(PKG_VERSION)/easytier-linux-aarch64-v\$(PKG_VERSION).zip" "prerelease"

if [ -f ./OpenWrt-momo/momo/Makefile ]; then
	sed -i 's/ +sing-box//g' ./OpenWrt-momo/momo/Makefile
	cat ./OpenWrt-momo/momo/Makefile
fi

#删除官方的默认插件
rm -rf ../feeds/luci/applications/luci-app-{passwall*,mosdns,dockerman,dae*,bypass*}
rm -rf ../feeds/packages/net/{v2ray-geodata,dae*}

REMOVE_PACKAGE \
	"sing-box" \
	"luci-app-vlmcsd" \
	"vlmcsd" \
	"luci-app-zerotier" \
	"zerotier" \
	"openclash" \
	"homeproxy" \
	"nikki" \
	"passwall" \
	"passwall2" \
	"luci-app-tailscale" \
	"tailscale" \
	"vnt" \
	"ddns-go" \
	"luci-app-lucky" \
	"lucky" \
	"gecoosac"

cp -r $GITHUB_WORKSPACE/package/* ./
rm -rf ./sing-box
#修复daed/Makefile
rm -rf luci-app-daed/daed/Makefile && cp -r $GITHUB_WORKSPACE/patches/daed/Makefile luci-app-daed/daed/
cat luci-app-daed/daed/Makefile
#修复libubox报错
#sed -i '/include $(INCLUDE_DIR)\/cmake.mk/a PKG_BUILD_FLAGS:=no-werror' ../package/libs/libubox/Makefile
#sed -i 's|TARGET_CFLAGS += -I$(STAGING_DIR)/usr/include|& -Wno-error=format-nonliteral -Wno-format-nonliteral|' ../package/libs/libubox/Makefile
#cat ../package/libs/libubox/Makefile
