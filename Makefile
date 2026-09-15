TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SideButtonActions
SideButtonActions_FILES = Tweak.xm
SideButtonActions_CFLAGS = -fobjc-arc
SideButtonActions_FRAMEWORKS = Foundation AVFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += SideButtonActionsPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
