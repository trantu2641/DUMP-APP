TARGET := iphone:clang:latest:16.0

ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SHAHierarchyDump

SHAHierarchyDump_FILES = Tweak.xm
SHAHierarchyDump_CFLAGS = -fobjc-arc
SHAHierarchyDump_FRAMEWORKS = Foundation

SHAHierarchyDump_PLIST_FILES = \
    SHAHierarchyDump.plist

include $(THEOS_MAKE_PATH)/tweak.mk
