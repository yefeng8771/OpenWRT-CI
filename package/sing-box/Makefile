include $(TOPDIR)/rules.mk

PKG_NAME:=sing-box
PKG_VERSION:=1.13.8-ref1nd
PKG_RELEASE:=1
PKG_SOURCE_VERSION:=1.13.8-reF1nd

PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-linux-arm64-musl.tar.gz
PKG_SOURCE_URL:=https://github.com/reF1nd/sing-box-releases/releases/download/v$(PKG_SOURCE_VERSION)/
PKG_HASH:=skip

PKG_LICENSE:=GPL-3.0-only
PKG_MAINTAINER:=OpenWRT-CI
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/sing-box
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=sing-box universal proxy platform
  URL:=https://github.com/reF1nd/sing-box-releases
  DEPENDS:=+ca-bundle +kmod-tun +libpthread
endef

define Package/sing-box/description
  sing-box is a universal proxy platform supporting multiple protocols.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR) --strip-components=1
endef

define Build/Compile
	true
endef

define Package/sing-box/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sing-box $(1)/usr/bin/sing-box
endef

$(eval $(call BuildPackage,sing-box))
