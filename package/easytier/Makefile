include $(TOPDIR)/rules.mk

PKG_NAME:=easytier
PKG_VERSION:=2.6.1
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-linux-aarch64-v$(PKG_VERSION).zip
PKG_SOURCE_URL:=https://github.com/EasyTier/EasyTier/releases/download/v$(PKG_VERSION)/
PKG_HASH:=skip

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=OpenWRT-CI
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DEPENDS:=unzip/host

include $(INCLUDE_DIR)/package.mk

define Package/easytier
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=EasyTier mesh VPN
  URL:=https://github.com/EasyTier/EasyTier
  DEPENDS:=+ca-bundle +kmod-tun +libpthread
endef

define Package/easytier/description
  EasyTier is a simple decentralized mesh VPN with WireGuard support.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	unzip -q $(DL_DIR)/$(PKG_SOURCE) -d $(PKG_BUILD_DIR)
endef

define Build/Compile
	true
endef

define Package/easytier/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/easytier-core $(1)/usr/bin/easytier-core
	if [ -f $(PKG_BUILD_DIR)/easytier-cli ]; then \
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/easytier-cli $(1)/usr/bin/easytier-cli; \
	fi
endef

$(eval $(call BuildPackage,easytier))
