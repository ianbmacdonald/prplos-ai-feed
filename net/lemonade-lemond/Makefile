# OpenWrt / prplOS package: lemonade-lemond (prebuilt musl-native lemonade server for prplOS 5.1 x86_64)
#
# Packages the lemonade team's musl build of lemond (litert, tflite, onnxruntime and executorch recipes), built with
# the prplOS 5.1 x86_64 musl toolchain against the image's own libraries. This is a packaging recipe, not a source
# build. The recipe adds a procd service, an API-key-enforcing supervisor and a TR-181 firewall helper.
#
# Checked on a prplOS 5.1 x86_64 gateway before packaging: every recipe serves; a declarative router in
# user_models.json makes no network calls of its own; bound to the LAN with an API key, every route (admin included)
# answers 401 without the key.

include $(TOPDIR)/rules.mk

PKG_NAME:=lemonade-lemond
# The version is lemond's BUILD NUMBER, not its git hash: hashes are not ordered, so opkg can read a newer build as
# older and refuse the upgrade (seen with 6be19fdca vs 552245997). `lemond --version` prints 2026.41.0~<build>.<hash>.
PKG_VERSION:=2026.41.1706
PKG_RELEASE:=16

# Build 69080e669: beacon listener with an interface allow-list and trusted relays (a named relay may advertise a
# listed host's URL), public route names, classify-only routing/validate, parallel resumable model downloads.
# PKG_HASH is the release asset's sha256 (6,862,905 bytes); the SDK re-verifies it at download.
PKG_SOURCE:=lemonade-embeddable-2026.41.0-69080e669-prplos5.1-x86_64-musl.tar.gz
PKG_SOURCE_URL:=https://github.com/ianbmacdonald/lemonade/releases/download/prpl-demo-musl-2026.41.0-69080e669
PKG_HASH:=d37665c391defaff10470790cc58328911d0b20638d5b849d6bfd18c6ff2889c
# The tarball unpacks to a top-level dir of its own name (not $(PKG_NAME)-$(PKG_VERSION)).
PKG_BUILD_DIR:=$(BUILD_DIR)/lemonade-embeddable-2026.41.0-69080e669-prplos5.1-x86_64-musl

PKG_MAINTAINER:=Ian MacDonald <ian@netstatz.com>
# Apache-2.0 for lemond itself; GPL-2.0-only for this package's own scripts (supervisor, firewall helper, init).
PKG_LICENSE:=Apache-2.0 GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/lemonade-lemond
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=AI
  TITLE:=lemonade lemond - OpenAI-compatible AI inference router (prebuilt musl, prpl-demo)
  URL:=https://github.com/ianbmacdonald/lemonade
  # musl-native x86_64 only (the only published build). Each NEEDED library maps to the package that ships it in the
  # prplOS 5.1 image, by the name the image PROVIDES: libwebsockets4-full provides 'libwebsockets4' (not
  # 'libwebsockets-full'; opkg refuses the latter), libcurl4 provides 'libcurl', libstdcpp6 provides 'libstdcpp'.
  DEPENDS:=@x86_64 +zlib +libcurl +libwebsockets4 +libcap +libstdcpp
endef

define Package/lemonade-lemond/description
  lemonade's lemond server (litert, tflite and onnxruntime recipes; collection.router policies;
  cloud_providers routing). This package adds a procd service that binds ONLY the LAN address,
  refuses to start without a valid API key file, and runs lemond under a small supervisor that
  opens a source-restricted TR-181 firewall rule only while lemond listens (removed on any exit).
  Backend servers (litert-lm-server, tflite-server, ort-server, et-server) are separate.
endef

# The SDK's shared-library check cannot see which image packages provide these sonames (they are not built in the
# SDK). The gateway provides them through the DEPENDS above (zlib, libcurl4, libwebsockets4-full, libcap), which opkg
# enforces at install time.
define Package/lemonade-lemond/extra_provides
	echo 'libz.so.1'; echo 'libcurl.so.4'; echo 'libwebsockets.so.19'; echo 'libcap.so.2'
endef

define Package/lemonade-lemond/conffiles
/etc/config/lemond
/etc/lemond/config.json
/etc/lemond/user_models.json
endef

define Build/Compile
	true
endef

# lemond finds resources/ next to its own binary (/proc/self/exe), so binary + resources stay together.
define Package/lemonade-lemond/install
	$(INSTALL_DIR) $(1)/usr/lib/lemond
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lemond $(1)/usr/lib/lemond/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lemonade $(1)/usr/lib/lemond/
	$(CP) $(PKG_BUILD_DIR)/resources $(1)/usr/lib/lemond/
	$(CP) $(PKG_BUILD_DIR)/licenses $(1)/usr/lib/lemond/
	$(INSTALL_DIR) $(1)/usr/bin
	$(LN) ../lib/lemond/lemonade $(1)/usr/bin/lemonade
	$(INSTALL_DIR) $(1)/usr/libexec
	$(INSTALL_BIN) ./files/lemond-run $(1)/usr/libexec/lemond-run
	$(INSTALL_BIN) ./files/lemond-fw $(1)/usr/libexec/lemond-fw
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/lemond.init $(1)/etc/init.d/lemond
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/lemond.config $(1)/etc/config/lemond
	$(INSTALL_DIR) $(1)/etc/lemond
	$(INSTALL_CONF) ./files/config.json $(1)/etc/lemond/config.json
	$(INSTALL_CONF) ./files/user_models.json $(1)/etc/lemond/user_models.json
	# The API key is NOT shipped (never package a secret), so it cannot be a conffile (the SDK drops conffiles the
	# package does not install). keep.d is how sysupgrade keeps it.
	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) ./files/lemond.keep $(1)/lib/upgrade/keep.d/lemonade-lemond
endef

# Prebuilt by lemonade with the prplOS toolchain and already stripped; do not let the buildroot touch them.
RSTRIP:=:
STRIP:=:

$(eval $(call BuildPackage,lemonade-lemond))
