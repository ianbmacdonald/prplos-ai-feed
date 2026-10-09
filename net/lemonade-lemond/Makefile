# OpenWrt / prplOS package: lemonade-lemond (prebuilt musl-native lemonade server for prplOS, x86_64 and aarch64)
#
# Packages the lemonade team's musl build of lemond (litert, tflite, onnxruntime and executorch recipes), built with
# the prplOS 5.1 musl toolchains (x86_64, aarch64) against the image's own libraries. This is a packaging recipe, not a source
# build. The recipe adds a procd service, an API-key-enforcing supervisor and a TR-181 firewall helper.
#
# Checked on a prplOS 5.1 x86_64 gateway before packaging: every recipe serves; a declarative router in
# user_models.json makes no network calls of its own; bound to the LAN with an API key, every route (admin included)
# answers 401 without the key.

include $(TOPDIR)/rules.mk

PKG_NAME:=lemonade-lemond
# The version is lemond's BUILD NUMBER, not its git hash: hashes are not ordered, so opkg can read a newer build as
# older and refuse the upgrade (seen with 6be19fdca vs 552245997). `lemond --version` prints 2026.41.0~<build>.<hash>.
# The week comes first (<year>.<week>.<build>), so opkg orders by upstream's release week, then the build number;
# keep the week of the newest asset so a later build never reads as older.
PKG_VERSION:=2026.43.1734
PKG_RELEASE:=1

# Build 571d17e15 (2026.43.0~1734): 6e16ce1c3 plus three optional gateway limits in config.json. Unset, they keep
# 6e16ce1c3's behaviour: max_request_body_mb defaults to 100 (6e16ce1c3 had the same 100 MB cpp-httplib ceiling, now
# configurable; larger bodies get 413), request_receive_timeout (seconds a client has to send a whole request) and
# max_connections_per_client (per source address; loopback exempt) default to 0 = off. Runtime libraries unchanged.
# Suggested on a gateway: 32 / 30 / a cap ABOVE the largest legitimate client's own connection pool (a reverse proxy
# or portal in front of lemond is one address). On an IPv6 LAN one host can use many addresses: leave the cap off there.
# PKG_HASH is each release asset's sha256 (x86_64 6,897,942 bytes; aarch64 6,292,342 bytes, built with the prplOS 5.1
# aarch64 musl toolchain, -march=armv8-a+crc -mtune=cortex-a53). Both assets carry 2026.43.0 in their names.
ifeq ($(ARCH),aarch64)
  BUNDLE:=lemonade-embeddable-2026.43.0-571d17e15-prplos5-aarch64-musl
  PKG_HASH:=9b5b0312dc1229a189b80ec2898e513949d8db570da154b200ede817f3677a9c
else
  BUNDLE:=lemonade-embeddable-2026.43.0-571d17e15-prplos5.1-x86_64-musl
  PKG_HASH:=f5a57e4febb42b45b395dc555bcbcde9f1e03e3babf326220887a7a9a5d8fad3
endif
PKG_SOURCE:=$(BUNDLE).tar.gz
PKG_SOURCE_URL:=https://github.com/ianbmacdonald/lemonade/releases/download/prpl-demo-musl-2026.43.0-571d17e15
# The tarball unpacks to a top-level dir of its own name (not $(PKG_NAME)-$(PKG_VERSION)).
PKG_BUILD_DIR:=$(BUILD_DIR)/$(BUNDLE)

PKG_MAINTAINER:=Ian MacDonald <ian@netstatz.com>
# Apache-2.0 for lemond itself; GPL-2.0-only for this package's own scripts (supervisor, firewall helper, init).
PKG_LICENSE:=Apache-2.0 GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/lemonade-lemond
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=AI
  TITLE:=lemonade lemond - OpenAI-compatible AI inference router (prebuilt musl)
  URL:=https://github.com/ianbmacdonald/lemonade
  # musl-native x86_64 or aarch64 (both NEED the same libraries). Each NEEDED library maps to the package that ships it in the
  # prplOS 5.1 image, by the name the image PROVIDES: libwebsockets4-full provides 'libwebsockets4' (not
  # 'libwebsockets-full'; opkg refuses the latter), libcurl4 provides 'libcurl', libstdcpp6 provides 'libstdcpp'.
  DEPENDS:=@(x86_64||aarch64) +zlib +libcurl +libwebsockets4 +libcap +libstdcpp
  # lemond and the runtime servers it starts run as this unprivileged user; the supervisor stays root only to read
  # the root-only API key and to open/close the TR-181 firewall rule.
  USERID:=lemond=392:lemond=392
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
	$(INSTALL_DIR) $(1)/usr/share/lemond
	$(INSTALL_DATA) ./files/lemond-nocaps.json $(1)/usr/share/lemond/nocaps.json
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
