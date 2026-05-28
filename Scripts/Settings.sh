#!/bin/bash
. $(dirname "$(realpath "$0")")/function.sh
#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ DaeWRT-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	# 修改WIFI默认名称：re-cs-02 三频不假定 6G，按带宽排序，最大带宽为 QWRT6
	python3 - "$WIFI_UC" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
text = p.read_text()
if 'let ssid_candidates = [];' not in text:
    text = text.replace(
        'let config = uci.cursor().get_all("wireless") ?? {};\n\nfunction radio_exists(path, macaddr, phy, radio) {',
        '''let config = uci.cursor().get_all("wireless") ?? {};
let ssid_candidates = [];
let ssid_by_key = {};

function record_ssid_candidate(phy_name, radio_index, width, band_name) {
\tpush(ssid_candidates, [ sprintf('%s:%s', phy_name, radio_index), width, band_name ]);
}

function assign_ssids_by_bandwidth() {
\tssid_candidates = sort(ssid_candidates, (a, b) => b[1] - a[1]);
\tfor (let i = 0; i < length(ssid_candidates); i++)
\t\tssid_by_key[ssid_candidates[i][0]] = i == 0 ? 'QWRT6' : sprintf('QWRT%d', i + 1);
}

function radio_exists(path, macaddr, phy, radio) {''',
        1,
    )
    text = text.replace(
        '''for (let phy_name, phy in board.wlan) {
\tlet info = phy.info;
''',
        '''for (let phy_name, phy in board.wlan) {
\tlet info = phy.info;
\tif (!info || !length(info.bands))
\t\tcontinue;

\tlet radios = length(info.radios) > 0 ? info.radios : [{ bands: info.bands }];
\tfor (let radio in radios) {
\t\tlet band_name = filter(bands_order, (b) => radio.bands[b])[0];
\t\tif (!band_name)
\t\t\tcontinue;
\t\tlet band = info.bands[band_name];
\t\tlet width = band.max_width;
\t\tif (band_name == "2G")
\t\t\twidth = 20;
\t\telse if (width > 80)
\t\t\twidth = 80;
\t\trecord_ssid_candidate(phy_name, radio.index, width, band_name);
\t}
}
assign_ssids_by_bandwidth();

for (let phy_name, phy in board.wlan) {
\tlet info = phy.info;
''',
        1,
    )
text = text.replace(
    '''set ${si}.ssid='${defaults?.ssid || "ImmortalWRT"}'\n''',
    '''set ${si}.ssid='${defaults?.ssid || ssid_by_key[sprintf('%s:%s', phy_name, radio.index)] || "ImmortalWRT"}'\n''',
    1,
)
p.write_text(text)
PY
	grep -q 'ssid_by_key\|QWRT6' "$WIFI_UC" || { echo "mac80211.uc WIFI SSID bandwidth patch failed" >&2; exit 1; }
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

vlmcsd_patches="./feeds/packages/net/vlmcsd/patches/"
mkdir -p $vlmcsd_patches && cp -f ../patches/001-fix_compile_with_ccache.patch $vlmcsd_patches

sed -i 's/mirrors.vsean.net\/openwrt/mirror.nju.edu.cn\/immortalwrt/g' ./package/emortal/default-settings/files/99-default-settings-chinese

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
#echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#开启sqm-nss插件
	echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
	echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
	#设置NSS版本
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
	if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
	else
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
	fi
	#无WIFI配置调整Q6大小
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
	#其他调整
	echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> ./.config
fi
#亚瑟修复USB2.0日志报错问题
#wget -qO - https://github.com/davidtall/immortalwrt/commit/ce39feb4.patch | patch -p1
#cat ./target/linux/qualcommax/dts/ipq6000-re-ss-01.dts