export THEOS_DEVICE_IP   = 192.168.x.x
export THEOS_DEVICE_PORT = 22

# iOS 12.1 SDK - SDK cuoi co armv7, tuong thich iOS 7.0+
# iPhoneOS 13+ da bo armv7
TARGET  := iphone:clang:12.1:7.0

# armv7  = iPhone 4s, 5, 5c (32-bit)
# arm64  = iPhone 5s tro len (64-bit)
ARCHS   = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChatGPTCompatTweak

ChatGPTCompatTweak_FILES  = Tweak.x
ChatGPTCompatTweak_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
