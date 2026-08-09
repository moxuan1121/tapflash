TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = tapflash
tapflash_FILES = Tweak.xm
tapflash_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

TOOL_NAME = tapflashd
tapflashd_FILES = Daemon.m
tapflashd_FRAMEWORKS = AVFoundation
tapflashd_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
tapflashd_CODESIGN_FLAGS = -Stapflashd.entitlements
tapflashd_INSTALL_PATH = /usr/libexec

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/tool.mk
