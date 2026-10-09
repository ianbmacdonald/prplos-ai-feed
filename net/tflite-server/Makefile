# OpenWrt / prplOS package: tflite-server (lemonade backend server, prebuilt musl bundle)
#
# Packages the prebuilt musl bundle (x86_64 or aarch64) published at github.com/ianbmacdonald/tflite-server (lemonade writes and builds it,
# on the prplOS 5.1 musl toolchains; we package and verify, as for litert-lm-server). Nothing is compiled here.
# lemond starts the server as a subprocess: from PATH, or from an explicit path in its config.json. There is no
# service of its own (no init, no uci).
# The bundle unpacks to a top-level directory named like the asset, hence PKG_BUILD_DIR.

include $(TOPDIR)/rules.mk

PKG_NAME:=tflite-server
PKG_VERSION:=0.3.0
PKG_RELEASE:=1

# One prebuilt bundle per architecture; both are on the same release, each with its own sha256.
ifeq ($(ARCH),aarch64)
  BUNDLE:=tflite-server-musl-aarch64-v0.3.0
  PKG_HASH:=3040b976cc5fecec470027dbb2def2f9ea54008ad551f64c5eb281cf719ccc1d
else
  BUNDLE:=tflite-server-musl-x86_64-v0.3.0
  PKG_HASH:=5f4865f81431f6ff3858a4afd8f8ed7d984d7c18b97a4463dc9602eef2a8e2ef
endif
PKG_SOURCE:=$(BUNDLE).tar.gz
PKG_SOURCE_URL:=https://github.com/ianbmacdonald/tflite-server/releases/download/v0.3.0
PKG_BUILD_DIR:=$(BUILD_DIR)/$(BUNDLE)

PKG_MAINTAINER:=Ian MacDonald <ian@netstatz.com>
# Apache-2.0 for the server; the statically linked components are listed in the bundle's licenses/ (installed below),
# the Rust tokenizer crates in licenses/rust-crates.txt. GPL-2.0-only covers this package's own wrapper script.
PKG_LICENSE:=Apache-2.0 MIT BSD-2-Clause BSL-1.0 Unicode-3.0 Unlicense Zlib GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/tflite-server
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=AI
  TITLE:=LiteRT (TFLite) classification server for lemonade's tflite recipe (prebuilt musl bundle)
  URL:=https://github.com/ianbmacdonald/tflite-server
  # One prebuilt bundle per architecture (musl x86_64 or aarch64). It links the image's libstdc++ and libgcc_s.
  DEPENDS:=@(x86_64||aarch64) +libstdcpp +libgcc
endef

define Package/tflite-server/description
  LiteRT v2.2.0 (static) behind lemonade's /v1/classify contract: text classifiers
  (tokenizer + .tflite) and image CNNs (/classify/image), with an optional XNNPACK
  weight cache. Curated operator set: the 48 builtin ops the reference models of six
  gateway use cases need; a model needing another op fails to load, naming it.
  Started by lemond (lemonade-lemond), not as a service of its own.
  Source: github.com/ianbmacdonald/tflite-server.
endef

define Build/Compile
	true
endef

# Keep the bundle layout (bin/ beside licenses/); /usr/bin/tflite-server is a wrapper that execs the real path, so the
# binary's $ORIGIN is its own directory and not /usr/bin.
define Package/tflite-server/install
	$(INSTALL_DIR) $(1)/usr/lib/tflite-server/bin
	$(CP) $(PKG_BUILD_DIR)/bin/. $(1)/usr/lib/tflite-server/bin/
	# a bundle without licenses/ fails the build: shipping without notices is not an option
	$(CP) $(PKG_BUILD_DIR)/licenses $(1)/usr/lib/tflite-server/
	$(CP) $(PKG_BUILD_DIR)/BUILD-INFO.txt $(1)/usr/lib/tflite-server/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/tflite-server.run $(1)/usr/bin/tflite-server
endef

# Prebuilt, already-stripped binaries: never let the buildroot's strip touch them.
RSTRIP:=:
STRIP:=:

$(eval $(call BuildPackage,tflite-server))
