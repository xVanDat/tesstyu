export THEOS_DEVICE_IP   = 192.168.x.x
export THEOS_DEVICE_PORT = 22

# 12.4 = SDK cao nhat con armv7, va co trong theos/sdks
# KHONG dung "latest" vi se chon 16.5 (khong co armv7)
TARGET  := iphone:clang:12.4:7.0

ARCHS   = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChatGPTCompatTweak

ChatGPTCompatTweak_FILES  = Tweak.x
ChatGPTCompatTweak_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
