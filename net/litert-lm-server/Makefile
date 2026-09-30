# OpenWrt / prplOS package: litert-lm-server (LiteRT-LM OpenAI-compatible server, prebuilt bundle)
#
# Packages a prebuilt bundle published at github.com/ianbmacdonald/litert-lm-server; it does not build from source
# (LiteRT-LM is Bazel-only). One package, two bundles:
#   x86_64  - v0.3.0, musl-native: one statically linked binary (LiteRT-LM v0.17.1) plus a small lib/, found through
#             its RUNPATH ($ORIGIN/../lib). Uses the image's libstdc++, libgcc_s and zlib.
#   aarch64 - v0.2.2, a self-contained glibc bundle (its own loader and runtime) that runs on the musl host through
#             the wrapper. Built and packaged, but not yet run on hardware with this recipe.
# Each bundle unpacks to a top-level directory named like the asset (not $(PKG_NAME)-$(PKG_VERSION)), hence
# PKG_BUILD_DIR. The asset name carries the arch, the C library and the version.

include $(TOPDIR)/rules.mk

PKG_NAME:=litert-lm-server
PKG_RELEASE:=8

# Each arch pins its own bundle version (= PKG_VERSION, so an .ipk never claims a version it does not ship) and sha256
# (the SDK re-verifies it).
ifeq ($(ARCH),x86_64)
  BUNDLE_ARCH:=x86_64
  BUNDLE_LIBC:=musl
  BUNDLE_VERSION:=0.3.0
  PKG_VERSION:=0.3.0
  PKG_LICENSE:=Apache-2.0 MIT BSD-2-Clause BSD-3-Clause Zlib MPL-2.0 BSL-1.0 Unicode-3.0 libpng-2.0 GPL-2.0-only
  PKG_HASH:=18aab7e6d5c97c5020f1af9abc910c50c1ab386dc4a4c8f9a86b135391dbdb84
else ifeq ($(ARCH),aarch64)
  BUNDLE_ARCH:=aarch64
  BUNDLE_LIBC:=glibc
  BUNDLE_VERSION:=0.2.2
  PKG_VERSION:=0.2.2
  PKG_LICENSE:=Apache-2.0 MIT BSD-2-Clause BSD-3-Clause Zlib MPL-2.0 BSL-1.0 Unicode-3.0 libpng-2.0 LGPL-2.1-or-later GPL-3.0-with-GCC-exception GPL-2.0-only
  PKG_HASH:=c9afcef69e355a40c0205edbc219b6619987d5bc64ce029cf0232c8bfb1f9952
else
  PKG_VERSION:=0.3.0
  PKG_LICENSE:=Apache-2.0
  # NOT $(error) unconditionally: OpenWrt's metadata scan (DUMP=1) evaluates this file without the
  # target ARCH, and an unconditional error drops the package from menuconfig entirely ('NOT SELECTED').
  # Error only on a real build; DEPENDS below also guards selection.
  ifeq ($(DUMP),)
    $(error litert-lm-server: prebuilt bundles exist only for aarch64 and x86_64, not $(ARCH))
  endif
endif
PKG_SOURCE:=$(PKG_NAME)-$(BUNDLE_ARCH)-$(BUNDLE_LIBC)-v$(BUNDLE_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/ianbmacdonald/litert-lm-server/releases/download/v$(BUNDLE_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUNDLE_ARCH)-$(BUNDLE_LIBC)-v$(BUNDLE_VERSION)

PKG_MAINTAINER:=Ian MacDonald <ian@netstatz.com>
# Licences. x86_64 v0.3.0: Apache-2.0 plus the statically linked components listed in the bundle's licenses/INDEX.md
# (MIT, BSD-2/3-Clause, Zlib, MPL-2.0 Eigen headers, BSL-1.0, Unicode-3.0, libpng-2.0); no GPL/LGPL runtime is
# bundled. aarch64 v0.2.2 also carries a glibc runtime (LGPL-2.1-or-later) and libstdc++/libgcc (GPL-3.0 with the GCC
# runtime exception; OpenWrt's list form of SPDX 'GPL-3.0-or-later WITH GCC-exception-3.1'); their notices ship in the bundle's licenses/ and are installed below.
# PKG_LICENSE is set per arch above, because the two bundles redistribute different things (the aarch64 list is
# conservative: the same statically linked components are assumed, plus its glibc runtime). GPL-2.0-only covers this
# package's own scripts (wrapper, init, config).

include $(INCLUDE_DIR)/package.mk

define Package/litert-lm-server
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=AI
  TITLE:=LiteRT-LM OpenAI-compatible inference server (prebuilt bundle: musl on x86_64, glibc on aarch64)
  URL:=https://github.com/ianbmacdonald/litert-lm-server
  # Prebuilt bundles exist for exactly these two targets (see the header).
  DEPENDS:=@(aarch64||x86_64) +libstdcpp +libgcc +zlib
  # x86_64 (musl, v0.3.0) links the image's libstdc++, libgcc_s and zlib; the aarch64 glibc bundle carries its own
  # runtime, so the three are unused there but small.
endef

# The SDK's shared-library check cannot see which image packages provide these sonames (zlib is not built in the
# SDK). The gateway provides them through the DEPENDS above (zlib, libstdcpp6, libgcc1), which opkg enforces at
# install time; without this the SDK stops with "missing dependencies ... libz.so.1".
define Package/litert-lm-server/extra_provides
	echo 'libz.so.1'
endef

define Package/litert-lm-server/conffiles
/etc/config/litert-lm-server
endef

define Package/litert-lm-server/description
  Standalone OpenAI-compatible HTTP server wrapping Google LiteRT-LM's C ABI
  (CPU backend), launched by Lemonade as a subprocess backend. x86_64 ships
  a musl-native build; aarch64 a self-contained glibc bundle that runs on the
  musl host. Source: github.com/ianbmacdonald/litert-lm-server.
endef

# Prebuilt bundle — nothing to compile. The unpacked PKG_BUILD_DIR is the bundle tree.
define Build/Compile
	true
endef

# Bundle layout: bin/ and lib/ are SIBLINGS (bin/litert-lm-server, lib/..., licenses/). Both bundles find lib/ as
# $ORIGIN/../lib, so the install MUST PRESERVE bin/ vs lib/ (do not flatten).
define Package/litert-lm-server/install
	$(INSTALL_DIR) $(1)/usr/lib/litert-lm-server/bin $(1)/usr/lib/litert-lm-server/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/litert-lm-server $(1)/usr/lib/litert-lm-server/bin/
	# which C library this bundle uses; the wrapper branches on it (rather than inferring it from a missing loader)
	echo '$(BUNDLE_LIBC)' > $(1)/usr/lib/litert-lm-server/LIBC
	$(CP) $(PKG_BUILD_DIR)/lib/. $(1)/usr/lib/litert-lm-server/lib/
	# licence notices (the bundle's directory is lowercase licenses/)
	# a bundle without licenses/ fails the build: shipping without notices is not an option
	$(CP) $(PKG_BUILD_DIR)/licenses $(1)/usr/lib/litert-lm-server/
	# PATH wrapper: runs the musl binary directly, or the glibc binary through its bundled loader
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/litert-lm-server.run $(1)/usr/bin/litert-lm-server
	# procd init + uci config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/litert-lm-server.init $(1)/etc/init.d/litert-lm-server
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/litert-lm-server.config $(1)/etc/config/litert-lm-server
endef

# Prebuilt, already-stripped binaries: never let the buildroot's strip touch them (for the glibc bundle it could
# break the loader wiring, and it would fail only at package time).
RSTRIP:=:
STRIP:=:

$(eval $(call BuildPackage,litert-lm-server))
