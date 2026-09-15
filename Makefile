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

BUNDLE_NAME = SideButtonActionsPrefs
SideButtonActionsPrefs_FILES = SideButtonActionsPrefs/SBASettingsController.m
SideButtonActionsPrefs_RESOURCE_DIRS = SideButtonActionsPrefs/Resources
SideButtonActionsPrefs_FRAMEWORKS = UIKit
SideButtonActionsPrefs_PRIVATE_FRAMEWORKS = Preferences
SideButtonActionsPrefs_INSTALL_PATH = /Library/PreferenceBundles
SideButtonActionsPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
