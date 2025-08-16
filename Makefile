# Makefile for Page Reloader Tool

# Package information
PKG_NAME := page-reloader
PKG_VERSION := 1.0.0
PKG_RELEASE := 1

# OpenWrt package build
include $(TOPDIR)/rules.mk

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE := $(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL := https://github.com/your-username/page-reloader/releases/download/v$(PKG_VERSION)/
PKG_HASH := skip

include $(INCLUDE_DIR)/package.mk

define Package/page-reloader
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Page Reloader Tool for OpenWrt
	DEPENDS:=+wget
	MAINTAINER:=Your Name <your.email@example.com>
	URL:=https://github.com/your-username/page-reloader
endef

define Package/page-reloader/description
	A tool to monitor and reload web pages on OpenWrt routers.
	Automatically checks configured URLs and attempts to reload them if they become inaccessible.
	Supports GitHub integration and can be easily installed/uninstalled on OpenWrt systems.
endef

define Package/page-reloader/conffiles
/etc/page-reloader/config
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	# Nothing to compile, it's a shell script
endef

define Package/page-reloader/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/page-reloader
	$(INSTALL_DIR) $(1)/etc/init.d
	
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/page-reloader.sh $(1)/usr/bin/page-reloader
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/config $(1)/etc/page-reloader/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/page-reloader.init $(1)/etc/init.d/page-reloader
endef

define Package/page-reloader/postinst
#!/bin/sh
# Enable service
if [ -z "$${IPKG_INSTROOT}" ]; then
    /etc/init.d/page-reloader enable
    echo "Page Reloader installed successfully!"
    echo "Edit /etc/page-reloader/config to configure URLs"
    echo "Start with: /etc/init.d/page-reloader start"
fi
endef

define Package/page-reloader/prerm
#!/bin/sh
# Stop service before removal
if [ -z "$${IPKG_INSTROOT}" ]; then
    /etc/init.d/page-reloader stop
    /etc/init.d/page-reloader disable
fi
endef

$(eval $(call BuildPackage,page-reloader))

# Development targets
.PHONY: install uninstall clean package

install:
	@echo "Installing Page Reloader..."
	@chmod +x install.sh
	@./install.sh

uninstall:
	@echo "Uninstalling Page Reloader..."
	@chmod +x uninstall.sh
	@./uninstall.sh

clean:
	@echo "Cleaning build files..."
	@rm -rf build/
	@rm -f *.ipk

package:
	@echo "Creating package..."
	@mkdir -p build/src
	@cp page-reloader.sh build/src/
	@cp config.example build/src/config
	@cp page-reloader.init build/src/
	@cd build && tar -czf ../$(PKG_NAME)-$(PKG_VERSION).tar.gz src/

help:
	@echo "Available targets:"
	@echo "  install    - Install on current system"
	@echo "  uninstall  - Uninstall from current system"
	@echo "  package    - Create source package"
	@echo "  clean      - Clean build files"
	@echo "  help       - Show this help"
