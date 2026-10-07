# OpenWrt / prplOS package: et-server (lemonade backend server, prebuilt musl bundle; prpl-harness planning G006)
#
# Packages the prebuilt musl x86_64 bundle published at github.com/ianbmacdonald/et-server (lemonade writes and builds it,
# on our prplOS 5.1 musl toolchain; we package and verify, as for litert-lm-server). Nothing is compiled here.
# lemond starts the server as a subprocess: from PATH, or from an explicit path in its config.json. There is no
# service of its own (no init, no uci).
# The bundle unpacks to a top-level directory named like the asset, hence PKG_BUILD_DIR.

include $(TOPDIR)/rules.mk

PKG_NAME:=et-server
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

BUNDLE:=et-server-musl-x86_64-v0.1.0
PKG_SOURCE:=$(BUNDLE).tar.gz
PKG_SOURCE_URL:=https://github.com/ianbmacdonald/et-server/releases/download/v0.1.0
PKG_HASH:=ff56541d6111d8c3bd980aef041586bb118f666fb8b0642d26b67753813b758c
PKG_BUILD_DIR:=$(BUILD_DIR)/$(BUNDLE)

PKG_MAINTAINER:=Ian MacDonald <ian@netstatz.com>
# Apache-2.0 for the server; the statically linked components are listed in the bundle's licenses/ (installed below),
# the Rust tokenizer crates in licenses/rust-crates.txt. GPL-2.0-only covers this package's own wrapper script.
PKG_LICENSE:=Apache-2.0 BSD-3-Clause MIT BSD-2-Clause MPL-2.0 BSL-1.0 Unicode-3.0 Unlicense Zlib GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/et-server
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=AI
  TITLE:=ExecuTorch classification server for lemonade's executorch recipe (prebuilt musl bundle)
  URL:=https://github.com/ianbmacdonald/et-server
  # One prebuilt bundle, musl x86_64 only. It links the image's libstdc++ and libgcc_s.
  DEPENDS:=@x86_64 +libstdcpp +libgcc
endef

define Package/et-server/description
  ExecuTorch v1.5.1 (static, XNNPACK backend) behind lemonade's /v1/classify contract,
  with an optional weight cache.
  Started by lemond (lemonade-lemond), not as a service of its own.
  Source: github.com/ianbmacdonald/et-server.
endef

define Build/Compile
	true
endef

# Keep the bundle layout (bin/ beside licenses/); /usr/bin/et-server is a wrapper that execs the real path, so the
# binary's $ORIGIN is its own directory and not /usr/bin.
define Package/et-server/install
	$(INSTALL_DIR) $(1)/usr/lib/et-server/bin
	$(CP) $(PKG_BUILD_DIR)/bin/. $(1)/usr/lib/et-server/bin/
	# a bundle without licenses/ fails the build: shipping without notices is not an option
	$(CP) $(PKG_BUILD_DIR)/licenses $(1)/usr/lib/et-server/
	$(CP) $(PKG_BUILD_DIR)/BUILD-INFO.txt $(1)/usr/lib/et-server/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/et-server.run $(1)/usr/bin/et-server
endef

# Prebuilt, already-stripped binaries: never let the buildroot's strip touch them.
RSTRIP:=:
STRIP:=:

$(eval $(call BuildPackage,et-server))
