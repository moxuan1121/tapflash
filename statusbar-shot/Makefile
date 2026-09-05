TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk
TWEAK_NAME = RightStatusShot
RightStatusShot_FILES = Tweak.xm
RightStatusShot_CFLAGS = -fobjc-arc
RightStatusShot_FRAMEWORKS = Foundation UIKit
include $(THEOS_MAKE_PATH)/tweak.mk
