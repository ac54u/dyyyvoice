TARGET = iphone:clang:14.5:13.0
ARCHS = arm64 arm64e
DEBUG = 0
FINALPACKAGE = 1

TWEAK_NAME = DYYYVoice

# 这里把两个文件都加进去了
DYYYVoice_FILES = DYYYVoiceHook.xm DYYYVoiceUI.m

# 强制使用 ARC (自动管理内存)
DYYYVoice_CFLAGS = -fobjc-arc -w

INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

clean::
	@rm -rf .theos packages