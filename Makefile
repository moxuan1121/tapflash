TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = tapflash
tapflash_FILES = Tweak.xm
tapflash_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
tapflash_FRAMEWORKS = Foundation AVFoundation
tapflash_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk
