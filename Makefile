TARGET := iphone:clang:latest:16.0

ARCHS = arm64 arm64e

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SHAHierarchyDump

SHAHierarchyDump_FILES = Tweak.xm
SHAHierarchyDump_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
