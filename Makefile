TARGET = iphone:clang:14.5:13.0
ARCHS = arm64 arm64e
DEBUG = 0
FINALPACKAGE = 1

TWEAK_NAME = DYYYVoice

DYYYVoice_FILES = DYYYVoiceHook.xm DYYYVoiceUI.m

# 关键修改：加入了 -w (忽略所有警告) 和 -Wno-deprecated (忽略过时API报错)
DYYYVoice_CFLAGS = -fobjc-arc -w -Wno-deprecated-declarations

# 链接系统框架
DYYYVoice_FRAMEWORKS = UIKit Foundation AVFoundation AudioToolbox CoreAudio

INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

clean::
	@rm -rf .theos packages