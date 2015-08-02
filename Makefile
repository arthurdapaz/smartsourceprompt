GO_EASY_ON_ME = 1
TARGET = iphone:latest:5.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

TWEAK_NAME = SmartSourcePrompt
SmartSourcePrompt_FILES = Tweak.xm
SmartSourcePrompt_FRAMEWORKS = UIKit
SmartSourcePrompt_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Cydia"
