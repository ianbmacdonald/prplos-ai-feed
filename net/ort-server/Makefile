# OpenWrt / prplOS package: ort-server (lemonade backend server, prebuilt musl bundle)
#
# Packages the prebuilt musl bundle (x86_64 or aarch64) published at github.com/ianbmacdonald/ort-server (lemonade writes and builds it,
# on the prplOS 5.1 musl toolchains; we package and verify, as for litert-lm-server). Nothing is compiled here.
# lemond starts the server as a subprocess: from PATH, or from an explicit path in its config.json. There is no
# service of its own (no init, no uci).
# The bundle unpacks to a top-level directory named like the asset, hence PKG_BUILD_DIR.

include $(TOPDIR)/rules.mk

PKG_NAME:=ort-server
PKG_VERSION:=0.2.1
PKG_RELEASE:=1

# One prebuilt bundle per architecture; both are on the same release, each with its own sha256.
ifeq ($(ARCH),aarch64)
  BUNDLE:=ort-server-musl-aarch64-curated-v0.2.1-musl
  PKG_HASH:=ca13b4337310c83f570c54c1fa39d795e134d3021ea9a687ac6f904ee0c1ac1f
else
  BUNDLE:=ort-server-musl-x86_64-curated-v0.2.1-musl
  PKG_HASH:=9c4a52711779848d8d32333de27c33884612f796fdd29dc219967226a8cd2aee
endif
PKG_SOURCE:=$(BUNDLE).tar.gz
PKG_SOURCE_URL:=https://github.com/ianbmacdonald/ort-server/releases/download/v0.2.1-musl
PKG_BUILD_DIR:=$(BUILD_DIR)/$(BUNDLE)

PKG_MAINTAINER:=Ian MacDonald <ian@netstatz.com>
# Apache-2.0 for the server; the statically linked components are listed in the bundle's licenses/ (installed below),
# the Rust tokenizer crates in licenses/rust-crates.txt. GPL-2.0-only covers this package's own wrapper script.
PKG_LICENSE:=Apache-2.0 MIT BSD-2-Clause BSL-1.0 Unicode-3.0 Unlicense Zlib GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/ort-server
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=AI
  TITLE:=ONNX Runtime classification server for lemonade's onnxruntime recipe (prebuilt musl bundle)
  URL:=https://github.com/ianbmacdonald/ort-server
  # One prebuilt bundle per architecture (musl x86_64 or aarch64). It links the image's libstdc++ and libgcc_s.
  DEPENDS:=@(x86_64||aarch64) +libstdcpp +libgcc
endef

# libonnxruntime.so.1 ships INSIDE this package (bin/, found through the binary's RUNPATH $ORIGIN); the SDK's
# shared-library check does not look there, so declare it.
define Package/ort-server/extra_provides
	echo 'libonnxruntime.so.1'
endef

define Package/ort-server/description
  ONNX Runtime 1.30.0 minimal build behind lemonade's /v1/classify contract
  (text and /classify/image; loads .ort models only). Curated operator set: 60 entries,
  the reference models of six gateway use cases plus the BERT family; a model needing
  another operator fails to load, naming it. libonnxruntime.so.1 ships beside the binary.
  Started by lemond (lemonade-lemond), not as a service of its own.
  Source: github.com/ianbmacdonald/ort-server.
endef

define Build/Compile
	true
endef

# Keep the bundle layout (bin/ beside licenses/); /usr/bin/ort-server is a wrapper that execs the real path, so the
# binary's $ORIGIN is its own directory and not /usr/bin.
define Package/ort-server/install
	$(INSTALL_DIR) $(1)/usr/lib/ort-server/bin
	$(CP) $(PKG_BUILD_DIR)/bin/. $(1)/usr/lib/ort-server/bin/
	# a bundle without licenses/ fails the build: shipping without notices is not an option
	$(CP) $(PKG_BUILD_DIR)/licenses $(1)/usr/lib/ort-server/
	$(CP) $(PKG_BUILD_DIR)/BUILD-INFO.txt $(1)/usr/lib/ort-server/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/ort-server.run $(1)/usr/bin/ort-server
endef

# Prebuilt, already-stripped binaries: never let the buildroot's strip touch them.
RSTRIP:=:
STRIP:=:

$(eval $(call BuildPackage,ort-server))
